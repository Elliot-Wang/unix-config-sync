package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"slices"
	"strings"

	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
)

const filename = "chezmoi.json"

// Config is both unix-sync's machine-local state and a valid chezmoi config.
type Config struct {
	SourceDir string      `json:"sourceDir"`
	Data      MachineData `json:"data"`
	Diff      DiffConfig  `json:"diff,omitempty"`
}

type MachineData struct {
	Machine                 string                   `json:"machine"`
	Profile                 string                   `json:"profile"`
	OSID                    string                   `json:"osid"`
	Arch                    string                   `json:"arch"`
	ShellMode               string                   `json:"shellMode"`
	Applications            map[string]bool          `json:"applications"`
	Versions                map[string]string        `json:"versions,omitempty"`
	Packages                map[string][]string      `json:"packages,omitempty"`
	PackageSpecs            map[string][]PackageSpec `json:"packageSpecs,omitempty"`
	IgnoredApplicationPaths []string                 `json:"ignoredApplicationPaths"`
}

type PackageSpec struct {
	Name    string `json:"name"`
	Version string `json:"version"`
}

type DiffConfig struct {
	Pager string `json:"pager,omitempty"`
}

func Default(info platform.Info, sourceDir string, definitions manifest.Manifest) Config {
	profileID := "personal"
	profile, ok := definitions.Profile(profileID)
	if !ok {
		profile = definitions.Profiles[0]
		profileID = profile.ID
	}
	applications := make(map[string]bool, len(definitions.Applications))
	for _, application := range definitions.Applications {
		applications[application.ID] = (application.Required || profile.Includes(application.ID)) && application.Supports(info.OSID, info.Family())
	}
	value := Config{
		SourceDir: sourceDir,
		Data: MachineData{
			Machine:      info.Hostname,
			Profile:      profileID,
			OSID:         info.OSID,
			Arch:         info.Arch,
			ShellMode:    profile.ShellMode,
			Applications: applications,
			Versions:     make(map[string]string),
		},
		Diff: DiffConfig{},
	}
	RefreshManifestData(&value, definitions)
	return value
}

func Path() (string, error) {
	if path := os.Getenv("UNIX_SYNC_CONFIG"); path != "" {
		return filepath.Abs(path)
	}
	// Compatibility for early development builds.
	if path := os.Getenv("CONFIG_SYNC_CONFIG"); path != "" {
		return filepath.Abs(path)
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(home, ".config", "unix-sync", filename), nil
}

func Load(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Config{}, err
	}
	var value Config
	if err := json.Unmarshal(data, &value); err != nil {
		return Config{}, fmt.Errorf("parse %s: %w", path, err)
	}
	if value.Data.Applications == nil {
		value.Data.Applications = make(map[string]bool)
	}
	if value.Data.Packages == nil {
		value.Data.Packages = make(map[string][]string)
	}
	if value.Data.Versions == nil {
		value.Data.Versions = make(map[string]string)
	}
	if value.Data.PackageSpecs == nil {
		value.Data.PackageSpecs = make(map[string][]PackageSpec)
	}
	return value, nil
}

func Save(path string, value Config) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	data = append(data, '\n')
	temp, err := os.CreateTemp(filepath.Dir(path), ".chezmoi-*.json")
	if err != nil {
		return err
	}
	tempPath := temp.Name()
	defer os.Remove(tempPath)
	if err := temp.Chmod(0o600); err != nil {
		temp.Close()
		return err
	}
	if _, err := temp.Write(data); err != nil {
		temp.Close()
		return err
	}
	if err := temp.Sync(); err != nil {
		temp.Close()
		return err
	}
	if err := temp.Close(); err != nil {
		return err
	}
	if err := os.Rename(tempPath, path); err == nil {
		return nil
	} else if runtime.GOOS != "windows" {
		return err
	}
	// Windows cannot atomically replace an existing destination. Move the old
	// config aside first so it can be restored if installing the new file fails.
	backup, err := os.CreateTemp(filepath.Dir(path), ".chezmoi-backup-*.json")
	if err != nil {
		return err
	}
	backupPath := backup.Name()
	if err := backup.Close(); err != nil {
		return err
	}
	if err := os.Remove(backupPath); err != nil {
		return err
	}
	defer os.Remove(backupPath)
	movedExisting := false
	if err := os.Rename(path, backupPath); err == nil {
		movedExisting = true
	} else if !errors.Is(err, os.ErrNotExist) {
		return err
	}
	if err := os.Rename(tempPath, path); err != nil {
		if movedExisting {
			_ = os.Rename(backupPath, path)
		}
		return err
	}
	return nil
}

func (c Config) Validate(definitions manifest.Manifest, info platform.Info) error {
	if c.SourceDir == "" {
		return errors.New("sourceDir is required")
	}
	if c.Data.Machine == "" {
		return errors.New("machine is required")
	}
	profile, ok := definitions.Profile(c.Data.Profile)
	if !ok {
		return fmt.Errorf("unknown profile %q", c.Data.Profile)
	}
	if !manifest.ValidShellMode(c.Data.ShellMode) {
		return fmt.Errorf("unknown shellMode %q", c.Data.ShellMode)
	}
	if c.Data.ShellMode != profile.ShellMode {
		return fmt.Errorf("shellMode %q does not match profile %q (%s)", c.Data.ShellMode, profile.ID, profile.ShellMode)
	}
	known := make(map[string]struct{}, len(definitions.Applications))
	for _, application := range definitions.Applications {
		known[application.ID] = struct{}{}
		if application.Required && application.Supports(info.OSID, info.Family()) && !c.Data.Applications[application.ID] {
			return fmt.Errorf("required application %q cannot be disabled on %s", application.ID, info.OSID)
		}
		if c.Data.Applications[application.ID] && !application.Supports(info.OSID, info.Family()) {
			return fmt.Errorf("application %q is not supported on %s", application.ID, info.OSID)
		}
	}
	for applicationID := range c.Data.Applications {
		if _, ok := known[applicationID]; !ok {
			return fmt.Errorf("unknown application %q", applicationID)
		}
	}
	for applicationID, version := range c.Data.Versions {
		if _, ok := known[applicationID]; !ok {
			return fmt.Errorf("version policy references unknown application %q", applicationID)
		}
		if !manifest.ValidVersion(version) {
			return fmt.Errorf("application %q has invalid version %q", applicationID, version)
		}
	}
	if !slices.Contains([]string{"darwin", "windows", "linux"}, info.OS) {
		return fmt.Errorf("unsupported operating system %q", info.OS)
	}
	return nil
}

func ApplyProfile(value *Config, profile manifest.Profile, definitions manifest.Manifest, info platform.Info) {
	value.Data.Profile = profile.ID
	value.Data.ShellMode = profile.ShellMode
	value.Data.Applications = make(map[string]bool, len(definitions.Applications))
	for _, application := range definitions.Applications {
		value.Data.Applications[application.ID] = (application.Required || profile.Includes(application.ID)) && application.Supports(info.OSID, info.Family())
	}
	RefreshManifestData(value, definitions)
}

func RefreshManifestData(value *Config, definitions manifest.Manifest) {
	packages := make(map[string][]string)
	packageSpecs := make(map[string][]PackageSpec)
	var ignoredPaths []string
	for _, application := range definitions.Applications {
		if !value.Data.Applications[application.ID] {
			ignoredPaths = append(ignoredPaths, application.ConfigPaths...)
			continue
		}
		if application.Kind == "bootstrap" {
			continue
		}
		for platformID, packageName := range application.Packages {
			key := platformID
			if application.Kind == "desktop" {
				key += "Desktop"
			}
			packages[key] = append(packages[key], packageName)
			packageSpecs[key] = append(packageSpecs[key], PackageSpec{Name: packageName, Version: value.Version(application.ID)})
		}
	}
	for platformID := range packages {
		slices.Sort(packages[platformID])
		slices.SortFunc(packageSpecs[platformID], func(a, b PackageSpec) int { return strings.Compare(a.Name, b.Name) })
	}
	value.Data.Packages = packages
	value.Data.PackageSpecs = packageSpecs
	slices.Sort(ignoredPaths)
	value.Data.IgnoredApplicationPaths = ignoredPaths
}

func (c Config) Version(applicationID string) string {
	if version := c.Data.Versions[applicationID]; version != "" {
		return version
	}
	return "latest"
}

func (c *Config) SetVersion(applicationID, version string) {
	if c.Data.Versions == nil {
		c.Data.Versions = make(map[string]string)
	}
	if version == "" || version == "latest" {
		delete(c.Data.Versions, applicationID)
		return
	}
	c.Data.Versions[applicationID] = version
}

// Reconcile upgrades saved machine state after the manifest, hostname, or
// platform changes while preserving choices that are still valid.
func Reconcile(value *Config, definitions manifest.Manifest, info platform.Info) {
	if info.Hostname != "" {
		value.Data.Machine = info.Hostname
	}
	value.Data.OSID = info.OSID
	value.Data.Arch = info.Arch
	profile, profileExists := definitions.Profile(value.Data.Profile)
	if !profileExists {
		profile, profileExists = definitions.Profile("personal")
		if !profileExists {
			profile = definitions.Profiles[0]
		}
		value.Data.Profile = profile.ID
	}
	value.Data.ShellMode = profile.ShellMode
	applications := make(map[string]bool, len(definitions.Applications))
	versions := make(map[string]string, len(value.Data.Versions))
	for _, application := range definitions.Applications {
		enabled, exists := value.Data.Applications[application.ID]
		if !exists {
			enabled = profile.Includes(application.ID)
		}
		if application.Required {
			enabled = true
		}
		applications[application.ID] = enabled && application.Supports(info.OSID, info.Family())
		if version := value.Data.Versions[application.ID]; manifest.ValidVersion(version) && version != "" && version != "latest" {
			versions[application.ID] = version
		}
	}
	value.Data.Applications = applications
	value.Data.Versions = versions
	RefreshManifestData(value, definitions)
}
