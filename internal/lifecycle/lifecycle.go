package lifecycle

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"regexp"
	"slices"
	"strings"

	"github.com/Elliot-Wang/unix-config-sync/internal/config"
	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
	"github.com/Elliot-Wang/unix-config-sync/internal/runner"
)

type Action string

const (
	Keep        Action = "KEEP"
	Install     Action = "INSTALL"
	Update      Action = "UPDATE"
	SetVersion  Action = "VERSION"
	Pin         Action = "PIN"
	Remove      Action = "REMOVE"
	Ignore      Action = "IGNORE"
	Unsupported Action = "UNSUPPORTED"
)

type Mode string

const (
	ModeReconcile Mode = "reconcile"
	ModeUpgrade   Mode = "upgrade"
	ModeRemove    Mode = "remove"
)

type Fact struct {
	Installed string
	Available string
	Pinned    bool
	Error     string
}

type Item struct {
	ApplicationID string
	Label         string
	Package       string
	Desired       string
	Installed     string
	Available     string
	Pinned        bool
	Action        Action
	Detail        string
	Kind          string
}

type Operation struct {
	ApplicationID string
	Label         string
	Action        Action
	Command       string
	Args          []string
}

func Inspect(ctx context.Context, definitions manifest.Manifest, info platform.Info, executor runner.Runner) map[string]Fact {
	facts := make(map[string]Fact, len(definitions.Applications))
	switch info.Family() {
	case "darwin":
		inspectBrew(ctx, definitions, executor, facts)
	case "debian":
		inspectDebian(ctx, definitions, info, executor, facts)
	case "rhel":
		inspectRHEL(ctx, definitions, info, executor, facts)
	case "windows":
		inspectWinget(ctx, definitions, info, executor, facts)
	}
	inspectBootstrap(ctx, definitions, executor, facts)
	return facts
}

func Resolve(value config.Config, definitions manifest.Manifest, info platform.Info, facts map[string]Fact) []Item {
	items := make([]Item, 0, len(definitions.Applications))
	for _, application := range definitions.Applications {
		if !application.Supports(info.OSID, info.Family()) {
			continue
		}
		packageName, _ := application.Package(info.OSID, info.Family())
		fact := facts[application.ID]
		item := Item{
			ApplicationID: application.ID,
			Label:         application.Label,
			Package:       packageName,
			Desired:       value.Version(application.ID),
			Installed:     fact.Installed,
			Available:     fact.Available,
			Pinned:        fact.Pinned,
			Kind:          application.Kind,
		}
		enabled := value.Data.Applications[application.ID]
		switch {
		case fact.Error != "":
			item.Action, item.Detail = Unsupported, fact.Error
		case application.Kind == "bootstrap":
			if fact.Installed == "" {
				item.Action, item.Detail = Install, "bootstrap prerequisite is missing"
			} else {
				item.Action, item.Detail = Keep, "bootstrap prerequisite"
			}
		case !enabled && fact.Installed != "":
			item.Action, item.Detail = Remove, "disabled; config sync is off"
		case !enabled:
			item.Action, item.Detail = Ignore, "disabled; config sync is off"
		case item.Desired != "latest" && info.Family() == "darwin" && item.Desired != fact.Installed && item.Desired != fact.Available:
			item.Action, item.Detail = Unsupported, "Homebrew cannot generally restore arbitrary historical versions"
		case fact.Installed == "":
			item.Action, item.Detail = Install, packageName+" via "+info.PackageManager()
		case item.Desired != "latest" && item.Desired != fact.Installed:
			item.Action, item.Detail = SetVersion, "converge to exact version"
		case item.Desired != "latest" && !fact.Pinned && info.Family() == "darwin":
			item.Action, item.Detail = Pin, "lock the installed Homebrew version"
		case fact.Available != "" && fact.Available != fact.Installed && item.Desired == "latest":
			item.Action, item.Detail = Update, "new package-manager version available"
		default:
			item.Action, item.Detail = Keep, "desired state is satisfied"
		}
		items = append(items, item)
	}
	return items
}

func Operations(mode Mode, value config.Config, definitions manifest.Manifest, info platform.Info, facts map[string]Fact) ([]Operation, error) {
	items := Resolve(value, definitions, info, facts)
	operations := make([]Operation, 0)
	for _, item := range items {
		application, _ := definitions.Application(item.ApplicationID)
		if application.Kind == "bootstrap" {
			continue
		}
		if mode == ModeReconcile && item.Action == Unsupported && value.Data.Applications[item.ApplicationID] {
			return nil, fmt.Errorf("%s: %s", item.Label, item.Detail)
		}
		shouldRun := false
		switch mode {
		case ModeReconcile:
			shouldRun = item.Action == Install || item.Action == Update || item.Action == SetVersion || item.Action == Pin
		case ModeUpgrade:
			shouldRun = value.Data.Applications[item.ApplicationID] && item.Desired == "latest" && item.Installed != ""
		case ModeRemove:
			shouldRun = item.Action == Remove
		default:
			return nil, fmt.Errorf("unknown application lifecycle mode %q", mode)
		}
		if !shouldRun {
			continue
		}
		if item.Action == Unsupported {
			return nil, fmt.Errorf("%s: %s", item.Label, item.Detail)
		}
		op, err := operationFor(mode, item, application, info)
		if err != nil {
			return nil, err
		}
		operations = append(operations, op...)
	}
	return operations, nil
}

func Execute(ctx context.Context, operations []Operation, executor runner.Runner) error {
	for _, operation := range operations {
		if err := executor.Run(ctx, operation.Command, operation.Args...); err != nil {
			return fmt.Errorf("%s %s: %w", strings.ToLower(string(operation.Action)), operation.Label, err)
		}
	}
	return nil
}

func operationFor(mode Mode, item Item, application manifest.Application, info platform.Info) ([]Operation, error) {
	manager := info.PackageManager()
	action := item.Action
	if mode == ModeUpgrade {
		action = Update
	}
	args := []string{}
	switch info.Family() {
	case "darwin":
		kindFlag := []string{}
		if application.Kind == "desktop" {
			kindFlag = []string{"--cask"}
		}
		if mode != ModeRemove && item.Desired != "latest" {
			if item.Installed != item.Desired && item.Available != item.Desired {
				return nil, fmt.Errorf("%s: Homebrew cannot converge %s to arbitrary version %s; use a versioned formula or tap", item.Label, item.Package, item.Desired)
			}
			operations := make([]Operation, 0, 2)
			if item.Installed != item.Desired {
				installArgs := append([]string{"install"}, kindFlag...)
				installArgs = append(installArgs, item.Package)
				operations = append(operations, Operation{ApplicationID: item.ApplicationID, Label: item.Label, Action: Install, Command: manager, Args: installArgs})
			}
			pinArgs := append([]string{"pin"}, kindFlag...)
			pinArgs = append(pinArgs, item.Package)
			operations = append(operations, Operation{ApplicationID: item.ApplicationID, Label: item.Label, Action: Pin, Command: manager, Args: pinArgs})
			return operations, nil
		}
		operations := make([]Operation, 0, 2)
		if mode != ModeRemove && item.Pinned {
			unpinArgs := append([]string{"unpin"}, kindFlag...)
			unpinArgs = append(unpinArgs, item.Package)
			operations = append(operations, Operation{ApplicationID: item.ApplicationID, Label: item.Label, Action: Update, Command: manager, Args: unpinArgs})
		}
		switch {
		case mode == ModeRemove:
			args = append([]string{"uninstall"}, kindFlag...)
			args = append(args, item.Package)
		default:
			verb := "install"
			if item.Installed != "" {
				verb = "upgrade"
			}
			args = append([]string{verb}, kindFlag...)
			args = append(args, item.Package)
		}
		operations = append(operations, Operation{ApplicationID: item.ApplicationID, Label: item.Label, Action: action, Command: manager, Args: args})
		return operations, nil
	case "debian":
		packageSpec := item.Package
		installArgs := []string{"install", "-y"}
		if item.Desired != "latest" {
			packageSpec += "=" + item.Desired
			installArgs = append(installArgs, "--allow-downgrades")
		}
		switch mode {
		case ModeRemove:
			args = []string{"remove", "-y", item.Package}
		default:
			args = append(installArgs, packageSpec)
		}
	case "rhel":
		packageSpec := item.Package
		if item.Desired != "latest" {
			packageSpec += "-" + item.Desired
		}
		switch mode {
		case ModeRemove:
			args = []string{"remove", "-y", item.Package}
		case ModeUpgrade:
			args = []string{"upgrade", "-y", item.Package}
		default:
			args = []string{"install", "-y", packageSpec}
		}
	case "windows":
		base := []string{"--id", item.Package, "--exact", "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity"}
		switch mode {
		case ModeRemove:
			args = append([]string{"uninstall"}, base...)
		default:
			verb := "install"
			if item.Installed != "" {
				verb = "upgrade"
			}
			args = append([]string{verb}, base...)
			if item.Desired != "latest" {
				args = append(args, "--version", item.Desired)
			}
		}
	default:
		return nil, fmt.Errorf("application management is unsupported on %s", info.OSID)
	}
	command := manager
	if (info.Family() == "debian" || info.Family() == "rhel") && commandExists("sudo") {
		args = append([]string{manager}, args...)
		command = "sudo"
	}
	return []Operation{{ApplicationID: item.ApplicationID, Label: item.Label, Action: action, Command: command, Args: args}}, nil
}

func inspectBrew(ctx context.Context, definitions manifest.Manifest, executor runner.Runner, facts map[string]Fact) {
	packageToID := make(map[string]string)
	args := []string{"info", "--json=v2"}
	for _, application := range definitions.Applications {
		if application.Kind == "bootstrap" {
			continue
		}
		if name, ok := application.Package("darwin", "darwin"); ok {
			packageToID[name] = application.ID
			args = append(args, name)
		}
	}
	output, _ := executor.Output(ctx, "brew", args...)
	var payload struct {
		Formulae []struct {
			Name     string `json:"name"`
			Versions struct {
				Stable string `json:"stable"`
			} `json:"versions"`
			Installed []struct {
				Version string `json:"version"`
			} `json:"installed"`
			Pinned bool `json:"pinned"`
		} `json:"formulae"`
		Casks []struct {
			Token     string   `json:"token"`
			Version   string   `json:"version"`
			Installed []string `json:"installed"`
		} `json:"casks"`
	}
	if err := json.Unmarshal(output, &payload); err != nil {
		for _, id := range packageToID {
			facts[id] = Fact{Error: "cannot inspect Homebrew package state"}
		}
		return
	}
	for _, formula := range payload.Formulae {
		fact := Fact{Available: formula.Versions.Stable, Pinned: formula.Pinned}
		if len(formula.Installed) > 0 {
			fact.Installed = formula.Installed[len(formula.Installed)-1].Version
		}
		facts[packageToID[formula.Name]] = fact
	}
	for _, cask := range payload.Casks {
		fact := Fact{Available: cask.Version}
		if len(cask.Installed) > 0 {
			fact.Installed = cask.Installed[len(cask.Installed)-1]
		}
		facts[packageToID[cask.Token]] = fact
	}
}

func inspectDebian(ctx context.Context, definitions manifest.Manifest, info platform.Info, executor runner.Runner, facts map[string]Fact) {
	for _, application := range definitions.Applications {
		if application.Kind == "bootstrap" {
			continue
		}
		name, ok := application.Package(info.OSID, info.Family())
		if !ok {
			continue
		}
		fact := Fact{}
		if output, err := executor.Output(ctx, "dpkg-query", "-W", "-f=${Version}", name); err == nil {
			fact.Installed = strings.TrimSpace(string(output))
		}
		if output, err := executor.Output(ctx, "apt-cache", "policy", name); err == nil {
			for _, line := range strings.Split(string(output), "\n") {
				line = strings.TrimSpace(line)
				if strings.HasPrefix(line, "Candidate:") {
					fact.Available = strings.TrimSpace(strings.TrimPrefix(line, "Candidate:"))
				}
			}
		}
		facts[application.ID] = fact
	}
}

func inspectRHEL(ctx context.Context, definitions manifest.Manifest, info platform.Info, executor runner.Runner, facts map[string]Fact) {
	for _, application := range definitions.Applications {
		if application.Kind == "bootstrap" {
			continue
		}
		name, ok := application.Package(info.OSID, info.Family())
		if !ok {
			continue
		}
		fact := Fact{}
		if output, err := executor.Output(ctx, "rpm", "-q", "--qf", "%{VERSION}-%{RELEASE}", name); err == nil {
			fact.Installed = strings.TrimSpace(string(output))
		}
		if output, err := executor.Output(ctx, info.PackageManager(), "--quiet", "list", "--showduplicates", name); err == nil {
			for _, line := range strings.Split(string(output), "\n") {
				fields := strings.Fields(line)
				if len(fields) >= 2 && (fields[0] == name || strings.HasPrefix(fields[0], name+".")) {
					fact.Available = fields[1]
				}
			}
		}
		facts[application.ID] = fact
	}
}

func inspectWinget(ctx context.Context, definitions manifest.Manifest, info platform.Info, executor runner.Runner, facts map[string]Fact) {
	for _, application := range definitions.Applications {
		if application.Kind == "bootstrap" {
			continue
		}
		name, ok := application.Package(info.OSID, info.Family())
		if !ok {
			continue
		}
		fact := Fact{}
		if output, err := executor.Output(ctx, "winget", "list", "--id", name, "--exact", "--disable-interactivity"); err == nil {
			for _, line := range strings.Split(string(output), "\n") {
				fields := strings.Fields(line)
				if index := slices.Index(fields, name); index >= 0 && index+1 < len(fields) {
					fact.Installed = fields[index+1]
				}
			}
		}
		if output, err := executor.Output(ctx, "winget", "show", "--id", name, "--exact", "--versions", "--disable-interactivity"); err == nil {
			fact.Available = firstVersion(string(output))
		}
		facts[application.ID] = fact
	}
}

var versionFinder = regexp.MustCompile(`[0-9]+(?:[.][0-9A-Za-z_-]+)+`)

func inspectBootstrap(ctx context.Context, definitions manifest.Manifest, executor runner.Runner, facts map[string]Fact) {
	commands := map[string][]string{
		"homebrew": {"brew", "--version"},
		"chezmoi":  {"chezmoi", "--version"},
	}
	for _, application := range definitions.Applications {
		if application.Kind != "bootstrap" {
			continue
		}
		command, ok := commands[application.ID]
		if !ok {
			continue
		}
		output, err := executor.Output(ctx, command[0], command[1:]...)
		if err != nil {
			facts[application.ID] = Fact{}
			continue
		}
		facts[application.ID] = Fact{Installed: firstVersion(string(output))}
	}
}

func firstVersion(output string) string {
	return versionFinder.FindString(output)
}

func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}
