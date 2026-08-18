package app

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/Elliot-Wang/unix-config-sync/internal/chezmoi"
	"github.com/Elliot-Wang/unix-config-sync/internal/config"
	"github.com/Elliot-Wang/unix-config-sync/internal/lifecycle"
	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/plan"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
	"github.com/Elliot-Wang/unix-config-sync/internal/runner"
	"github.com/Elliot-Wang/unix-config-sync/internal/syncui"
	"github.com/Elliot-Wang/unix-config-sync/internal/tui"
)

var Version = "dev"

type runtimeState struct {
	Value           config.Config
	Definitions     manifest.Manifest
	EffectiveConfig string
	Persisted       bool
	cleanup         func()
}

func Run(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	command := "sync"
	if len(args) > 0 && !strings.HasPrefix(args[0], "-") {
		command = args[0]
		args = args[1:]
	}
	if command == "help" || command == "-h" || command == "--help" {
		printHelp(stdout)
		return nil
	}
	if command == "version" {
		fmt.Fprintln(stdout, Version)
		return nil
	}

	info := platform.Detect()
	persistentConfig, err := config.Path()
	if err != nil {
		return err
	}
	executor := runner.Exec{Stdin: stdin, Stdout: stdout, Stderr: stderr}

	switch command {
	case "sync":
		return runSync(args, info, persistentConfig, executor, stdout)
	case "settings", "profile", "init":
		return runSettings(args, info, persistentConfig, executor, stdout)
	case "status", "diff", "apply", "update", "capture":
		return runDirect(command, args, info, persistentConfig, executor, stdout)
	case "doctor":
		return runDoctor(args, info, persistentConfig, executor, stdout)
	default:
		return fmt.Errorf("unknown command %q; run unix-sync help", command)
	}
}

func runSync(args []string, info platform.Info, persistentConfig string, executor runner.Exec, stdout io.Writer) error {
	flags := flag.NewFlagSet("sync", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	sourceFlag := flags.String("source", "", "local chezmoi source directory")
	dryRun := flags.Bool("dry-run", false, "print a read-only report instead of opening the TUI")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 0 {
		return fmt.Errorf("unexpected sync arguments: %s", strings.Join(flags.Args(), " "))
	}

	notice := ""
	for {
		state, err := loadRuntimeState(info, persistentConfig, *sourceFlag)
		if err != nil {
			return err
		}
		client := chezmoi.Client{ConfigPath: state.EffectiveConfig, Runner: executor}
		snapshot := collectSnapshot(context.Background(), state, info, client, executor)
		snapshot.Notice = notice
		if *dryRun {
			printDryRun(stdout, snapshot)
			state.cleanup()
			return nil
		}

		result, err := syncui.Run(snapshot)
		if err != nil {
			state.cleanup()
			return err
		}
		switch result.Action {
		case syncui.ActionRefresh:
			state.cleanup()
			notice = "Preview refreshed."
			continue
		case syncui.ActionSettings:
			sourceDir := state.Value.SourceDir
			state.cleanup()
			if err := runSettings([]string{"--source", sourceDir}, info, persistentConfig, executor, stdout); err != nil {
				return err
			}
			notice = "Machine settings saved; preview recalculated."
			continue
		case syncui.ActionApply:
			err = client.Apply(context.Background(), true)
			notice = "Source state applied to managed home files."
		case syncui.ActionCapture:
			err = client.ReAdd(context.Background())
			notice = "Managed home changes captured; Git was not committed or pushed."
		case syncui.ActionUpdate:
			err = client.Update(context.Background())
			notice = "Source pulled and applied; preview recalculated."
		default:
			state.cleanup()
			return nil
		}
		state.cleanup()
		if err != nil {
			return err
		}
		continue
	}
}

func runSettings(args []string, info platform.Info, persistentConfig string, executor runner.Exec, stdout io.Writer) error {
	flags := flag.NewFlagSet("settings", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	sourceFlag := flags.String("source", "", "local chezmoi source directory")
	profileFlag := flags.String("profile", "", "profile id")
	enableAppsFlag := flags.String("enable-apps", "", "comma-separated application ids")
	disableAppsFlag := flags.String("disable-apps", "", "comma-separated application ids")
	nonInteractive := flags.Bool("non-interactive", false, "skip the settings TUI")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 0 {
		return fmt.Errorf("unexpected settings arguments: %s", strings.Join(flags.Args(), " "))
	}

	existing, loadErr := config.Load(persistentConfig)
	if loadErr != nil && !errors.Is(loadErr, os.ErrNotExist) {
		return loadErr
	}
	sourceDir := *sourceFlag
	if sourceDir == "" && loadErr == nil {
		sourceDir = existing.SourceDir
	}
	if sourceDir == "" {
		var err error
		sourceDir, err = FindSourceDir("")
		if err != nil {
			return err
		}
	}
	absoluteSource, err := filepath.Abs(sourceDir)
	if err != nil {
		return err
	}
	definitions, err := manifest.Load(absoluteSource)
	if err != nil {
		return err
	}
	value := config.Default(info, absoluteSource, definitions)
	if loadErr == nil && existing.SourceDir == absoluteSource {
		value = existing
		config.Reconcile(&value, definitions, info)
	}
	if *profileFlag != "" {
		profile, ok := definitions.Profile(*profileFlag)
		if !ok {
			return fmt.Errorf("unknown profile %q", *profileFlag)
		}
		config.ApplyProfile(&value, profile, definitions, info)
	}
	if err := setApplications(&value, definitions, info, *enableAppsFlag, true); err != nil {
		return err
	}
	if err := setApplications(&value, definitions, info, *disableAppsFlag, false); err != nil {
		return err
	}
	config.RefreshManifestData(&value, definitions)
	facts := lifecycle.Inspect(context.Background(), definitions, info, executor)
	action := lifecycle.Mode("")
	if !*nonInteractive {
		result, err := tui.Run(value, definitions, info, facts)
		if err != nil {
			return err
		}
		if result.Canceled {
			fmt.Fprintln(stdout, "Settings canceled; no files changed.")
			return nil
		}
		value = result.Config
		action = result.Action
	}
	if err := value.Validate(definitions, info); err != nil {
		return err
	}
	config.RefreshManifestData(&value, definitions)
	var operations []lifecycle.Operation
	if action != "" {
		operations, err = lifecycle.Operations(action, value, definitions, info, facts)
		if err != nil {
			return err
		}
	}
	if err := config.Save(persistentConfig, value); err != nil {
		return fmt.Errorf("save machine settings: %w", err)
	}
	fmt.Fprintf(stdout, "Saved machine settings to %s; no home files were changed.\n", persistentConfig)
	printPlan(stdout, plan.ResolveConfig(value, info))
	printLifecyclePlan(stdout, lifecycle.Resolve(value, definitions, info, facts))
	if action != "" {
		if len(operations) == 0 {
			fmt.Fprintln(stdout, "Application state already satisfies this action.")
			return nil
		}
		if err := lifecycle.Execute(context.Background(), operations, executor); err != nil {
			return err
		}
		fmt.Fprintf(stdout, "Application action %s completed (%d operation(s)); managed home config files were not deleted.\n", action, len(operations))
	}
	return nil
}

func runDirect(command string, args []string, info platform.Info, persistentConfig string, executor runner.Exec, stdout io.Writer) error {
	flags := flag.NewFlagSet(command, flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	sourceFlag := flags.String("source", "", "local chezmoi source directory")
	dryRun := flags.Bool("dry-run", false, "show the operation without changing files")
	if err := flags.Parse(args); err != nil {
		return err
	}
	targets := flags.Args()
	if command != "capture" && len(targets) != 0 {
		return fmt.Errorf("%s does not accept positional arguments", command)
	}
	state, err := loadRuntimeState(info, persistentConfig, *sourceFlag)
	if err != nil {
		return err
	}
	defer state.cleanup()
	client := chezmoi.Client{ConfigPath: state.EffectiveConfig, Runner: executor}
	if !client.Available() {
		return errors.New("chezmoi is not installed; run the platform bootstrap first")
	}
	ctx := context.Background()
	diff := ""
	if command != "status" {
		diff, err = client.DiffOutput(ctx)
		if err != nil {
			return err
		}
	}
	switch command {
	case "status":
		fmt.Fprintf(stdout, "%s · %s/%s · profile=%s · shell=%s\n", state.Value.Data.Machine, info.OSID, info.Arch, state.Value.Data.Profile, state.Value.Data.ShellMode)
		return client.Status(ctx)
	case "diff":
		printDiff(stdout, diff)
		return nil
	case "apply":
		printDiff(stdout, diff)
		if *dryRun {
			fmt.Fprintln(stdout, "DRY RUN: no home files were changed.")
			return nil
		}
		return client.Apply(ctx, true)
	case "update":
		printDiff(stdout, diff)
		if *dryRun {
			fmt.Fprintln(stdout, "DRY RUN: the remote was not fetched and no home files were changed.")
			return nil
		}
		return client.Update(ctx)
	case "capture":
		fmt.Fprintln(stdout, "Capture direction: managed home files → source repository")
		printDiff(stdout, diff)
		if *dryRun {
			fmt.Fprintln(stdout, "DRY RUN: the source repository was not changed.")
			return nil
		}
		return client.ReAdd(ctx, targets...)
	default:
		return nil
	}
}

func loadRuntimeState(info platform.Info, persistentConfig, sourceOverride string) (runtimeState, error) {
	state := runtimeState{}
	existing, loadErr := config.Load(persistentConfig)
	if loadErr != nil && !errors.Is(loadErr, os.ErrNotExist) {
		return state, loadErr
	}
	sourceDir := sourceOverride
	if sourceDir == "" && loadErr == nil {
		sourceDir = existing.SourceDir
		state.Persisted = true
	}
	if sourceDir == "" {
		var err error
		sourceDir, err = FindSourceDir("")
		if err != nil {
			return state, fmt.Errorf("no saved settings and no source found: %w", err)
		}
	}
	absoluteSource, err := filepath.Abs(sourceDir)
	if err != nil {
		return state, err
	}
	definitions, err := manifest.Load(absoluteSource)
	if err != nil {
		return state, err
	}
	value := config.Default(info, absoluteSource, definitions)
	if loadErr == nil && existing.SourceDir == absoluteSource {
		value = existing
		config.Reconcile(&value, definitions, info)
		state.Persisted = true
	}
	config.RefreshManifestData(&value, definitions)
	if err := value.Validate(definitions, info); err != nil {
		return state, err
	}
	temporaryDir, err := os.MkdirTemp("", "unix-sync-preview-")
	if err != nil {
		return state, err
	}
	temporaryConfig := filepath.Join(temporaryDir, "chezmoi.json")
	if err := config.Save(temporaryConfig, value); err != nil {
		_ = os.RemoveAll(temporaryDir)
		return state, err
	}
	state.Value = value
	state.Definitions = definitions
	state.EffectiveConfig = temporaryConfig
	state.cleanup = func() { _ = os.RemoveAll(temporaryDir) }
	return state, nil
}

func collectSnapshot(ctx context.Context, state runtimeState, info platform.Info, client chezmoi.Client, executor runner.Exec) syncui.Snapshot {
	snapshot := syncui.Snapshot{
		Machine:   state.Value.Data.Machine,
		OSID:      info.OSID,
		Arch:      info.Arch,
		Profile:   state.Value.Data.Profile,
		ShellMode: state.Value.Data.ShellMode,
		SourceDir: state.Value.SourceDir,
		Ephemeral: !state.Persisted,
	}
	if output, err := executor.Output(ctx, "git", "-C", state.Value.SourceDir, "status", "--short", "--branch"); err == nil {
		snapshot.RepoStatus = string(output)
	} else {
		snapshot.RepoStatus = "git status unavailable: " + err.Error()
	}
	if !client.Available() {
		snapshot.BackendError = "chezmoi is not installed"
		return snapshot
	}
	status, err := client.StatusOutput(ctx)
	if err != nil {
		snapshot.BackendError = err.Error()
		return snapshot
	}
	diff, err := client.DiffOutput(ctx)
	if err != nil {
		snapshot.BackendError = err.Error()
		return snapshot
	}
	snapshot.ManagedStatus = status
	snapshot.Diff = diff
	return snapshot
}

func printDryRun(output io.Writer, snapshot syncui.Snapshot) {
	fmt.Fprintln(output, "UNIX-SYNC READ-ONLY DRY RUN")
	fmt.Fprintf(output, "%s · %s/%s · profile=%s · shell=%s\n", snapshot.Machine, snapshot.OSID, snapshot.Arch, snapshot.Profile, snapshot.ShellMode)
	fmt.Fprintln(output, "source:", snapshot.SourceDir)
	if snapshot.Ephemeral {
		fmt.Fprintln(output, "settings: temporary defaults; no initialization was performed")
	}
	if snapshot.BackendError != "" {
		fmt.Fprintln(output, "preview unavailable:", snapshot.BackendError)
	} else {
		writeSection(output, "MANAGED STATUS", snapshot.ManagedStatus, "No managed-file drift.")
		writeSection(output, "SOURCE -> HOME DIFF", snapshot.Diff, "No source -> home changes.")
	}
	writeSection(output, "SOURCE REPOSITORY", snapshot.RepoStatus, "Source repository is clean.")
	fmt.Fprintln(output, "No files were changed and no remote was fetched.")
}

func writeSection(output io.Writer, title, value, empty string) {
	fmt.Fprintf(output, "\n[%s]\n", title)
	if strings.TrimSpace(value) == "" {
		fmt.Fprintln(output, empty)
		return
	}
	fmt.Fprint(output, value)
	if !strings.HasSuffix(value, "\n") {
		fmt.Fprintln(output)
	}
}

func printDiff(output io.Writer, diff string) {
	if strings.TrimSpace(diff) == "" {
		fmt.Fprintln(output, "No managed-file differences.")
		return
	}
	fmt.Fprint(output, diff)
	if !strings.HasSuffix(diff, "\n") {
		fmt.Fprintln(output)
	}
}

func runDoctor(args []string, info platform.Info, persistentConfig string, executor runner.Exec, stdout io.Writer) error {
	flags := flag.NewFlagSet("doctor", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	sourceFlag := flags.String("source", "", "local chezmoi source directory")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 0 {
		return errors.New("doctor does not accept positional arguments")
	}
	state, err := loadRuntimeState(info, persistentConfig, *sourceFlag)
	if err != nil {
		return err
	}
	defer state.cleanup()
	client := chezmoi.Client{ConfigPath: state.EffectiveConfig, Runner: executor}
	type check struct {
		name   string
		detail string
		ok     bool
	}
	settingsDetail := persistentConfig
	if !state.Persisted {
		settingsDetail = "not saved; preview uses temporary defaults"
	}
	checks := []check{
		{name: "platform", detail: info.OSID + "/" + info.Arch, ok: true},
		{name: "git", detail: executablePath("git"), ok: commandExists("git")},
		{name: "chezmoi", detail: executablePath("chezmoi"), ok: client.Available()},
		{name: "source", detail: state.Value.SourceDir, ok: true},
		{name: "settings", detail: settingsDetail, ok: true},
	}
	requirePackageManager := len(state.Value.Data.Packages) > 0
	if manager := info.PackageManager(); requirePackageManager && manager != "" {
		checks = append(checks, check{name: "package manager", detail: executablePath(manager), ok: commandExists(manager)})
	}
	failed := false
	for _, item := range checks {
		mark := "✓"
		if !item.ok {
			mark = "✗"
			failed = true
		}
		fmt.Fprintf(stdout, "%s %-16s %s\n", mark, item.name, item.detail)
	}
	if failed {
		return errors.New("doctor found missing requirements")
	}
	return client.Doctor(context.Background())
}

func setApplications(value *config.Config, definitions manifest.Manifest, info platform.Info, raw string, enabled bool) error {
	if raw == "" {
		return nil
	}
	known := make(map[string]manifest.Application, len(definitions.Applications))
	for _, application := range definitions.Applications {
		known[application.ID] = application
	}
	for _, id := range strings.Split(raw, ",") {
		id = strings.TrimSpace(id)
		application, ok := known[id]
		if !ok {
			return fmt.Errorf("unknown application %q", id)
		}
		if enabled && !application.Supports(info.OSID, info.Family()) {
			return fmt.Errorf("application %q is not supported on %s", id, info.OSID)
		}
		if !enabled && application.Required && application.Supports(info.OSID, info.Family()) {
			return fmt.Errorf("application %q is required on %s and cannot be disabled", id, info.OSID)
		}
		value.Data.Applications[id] = enabled
	}
	return nil
}

func FindSourceDir(start string) (string, error) {
	if start == "" {
		var err error
		start, err = os.Getwd()
		if err != nil {
			return "", err
		}
	}
	current, err := filepath.Abs(start)
	if err != nil {
		return "", err
	}
	for {
		if fileExists(filepath.Join(current, manifest.Filename)) && fileExists(filepath.Join(current, ".chezmoiroot")) {
			return current, nil
		}
		parent := filepath.Dir(current)
		if parent == current {
			return "", fmt.Errorf("cannot find %s and .chezmoiroot above %s", manifest.Filename, start)
		}
		current = parent
	}
}

func printPlan(output io.Writer, items []plan.Item) {
	for _, item := range items {
		fmt.Fprintf(output, "%-7s %s", item.Action, item.Target)
		if item.Detail != "" {
			fmt.Fprintf(output, "  # %s", item.Detail)
		}
		fmt.Fprintln(output)
	}
}

func printLifecyclePlan(output io.Writer, items []lifecycle.Item) {
	for _, item := range items {
		installed := item.Installed
		if installed == "" {
			installed = "missing"
		}
		fmt.Fprintf(output, "%-11s %s  # desired=%s installed=%s", item.Action, item.Label, item.Desired, installed)
		if item.Available != "" && item.Available != item.Installed {
			fmt.Fprintf(output, " available=%s", item.Available)
		}
		fmt.Fprintln(output)
	}
}

func printHelp(output io.Writer) {
	commands := []string{
		"unix-sync                       Open the read-only-first sync TUI",
		"unix-sync --dry-run             Print a non-interactive read-only report",
		"unix-sync settings              Manage profiles, applications, and versions in the TUI",
		"unix-sync status                Show managed-file status",
		"unix-sync diff                  Print the complete source -> home diff",
		"unix-sync apply [--dry-run]      Apply source -> home interactively",
		"unix-sync capture [--dry-run]    Capture home -> source without Git commit",
		"unix-sync update [--dry-run]     Pull source and apply interactively",
		"unix-sync doctor                Check runtime requirements",
		"unix-sync version               Print the build version",
	}
	fmt.Fprintln(output, "unix-sync — terminal-only configuration synchronization")
	fmt.Fprintln(output)
	for _, command := range commands {
		fmt.Fprintln(output, "  "+command)
	}
}

func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func executablePath(name string) string {
	path, err := exec.LookPath(name)
	if err != nil {
		return "not found"
	}
	return path
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}
