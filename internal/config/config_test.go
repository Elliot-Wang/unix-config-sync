package config

import (
	"bytes"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"testing"

	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
)

func definitions() manifest.Manifest {
	return manifest.Manifest{
		SchemaVersion: 1,
		Applications: []manifest.Application{
			{ID: "git", Label: "Git", Required: true, Packages: map[string]string{"darwin": "git", "windows": "Git.Git"}},
			{ID: "zsh", Label: "Zsh", Packages: map[string]string{"darwin": "zsh", "rhel": "zsh"}},
			{ID: "wezterm", Label: "WezTerm", Kind: "desktop", Packages: map[string]string{"darwin": "wezterm"}},
		},
		Profiles: []manifest.Profile{{
			ID: "personal", Label: "Personal", ShellMode: manifest.ShellModern,
			Applications: []string{"zsh"},
		}},
	}
}

func TestSaveLoadRoundTrip(t *testing.T) {
	info := platform.Info{OS: "darwin", OSID: "darwin", Arch: "arm64", Hostname: "mac"}
	want := Default(info, "/tmp/dotfiles", definitions())
	path := filepath.Join(t.TempDir(), "chezmoi.json")
	if err := Save(path, want); err != nil {
		t.Fatal(err)
	}
	got, err := Load(path)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("Load(Save(config)) mismatch:\ngot:  %#v\nwant: %#v", got, want)
	}
}

func TestSaveKeepsEmptyIgnoredApplicationPathsForChezmoiTemplates(t *testing.T) {
	info := platform.Info{OS: "darwin", OSID: "darwin", Arch: "arm64", Hostname: "mac"}
	value := Default(info, "/tmp/dotfiles", definitions())
	path := filepath.Join(t.TempDir(), "chezmoi.json")
	if err := Save(path, value); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Contains(data, []byte(`"ignoredApplicationPaths": null`)) {
		t.Fatalf("saved config omitted template-required field:\n%s", data)
	}
}

func TestValidateRejectsUnsupportedApplication(t *testing.T) {
	info := platform.Info{OS: "windows", OSID: "windows", Arch: "amd64", Hostname: "pc"}
	value := Default(info, "C:/dotfiles", definitions())
	value.Data.Applications["zsh"] = true
	if err := value.Validate(definitions(), info); err == nil {
		t.Fatal("expected unsupported application error")
	}
}

func TestValidateRejectsDisabledRequiredApplication(t *testing.T) {
	info := platform.Info{OS: "darwin", OSID: "darwin", Arch: "arm64", Hostname: "mac"}
	value := Default(info, "/tmp/dotfiles", definitions())
	value.Data.Applications["git"] = false
	if err := value.Validate(definitions(), info); err == nil {
		t.Fatal("expected disabled required application error")
	}
}

func TestValidateRejectsShellModeOutsideProfile(t *testing.T) {
	info := platform.Info{OS: "darwin", OSID: "darwin", Arch: "arm64", Hostname: "mac"}
	value := Default(info, "/tmp/dotfiles", definitions())
	value.Data.ShellMode = manifest.ShellLegacy
	if err := value.Validate(definitions(), info); err == nil {
		t.Fatal("expected profile/shell mode mismatch error")
	}
}

func TestValidateRejectsUnsafeExactVersion(t *testing.T) {
	info := platform.Info{OS: "darwin", OSID: "darwin", Arch: "arm64", Hostname: "mac"}
	value := Default(info, "/tmp/dotfiles", definitions())
	value.Data.Versions["git"] = "2.0;touch-pwned"
	if err := value.Validate(definitions(), info); err == nil {
		t.Fatal("expected unsafe version to be rejected")
	}
}

func TestReconcileMigratesAndRemovesUnknownApplications(t *testing.T) {
	info := platform.Info{OS: "windows", OSID: "windows", Arch: "amd64", Hostname: "new-name"}
	value := Config{Data: MachineData{
		Machine: "old-name", Profile: "removed", ShellMode: "",
		Applications: map[string]bool{"zsh": true, "removed": true},
	}}
	Reconcile(&value, definitions(), info)
	if value.Data.Machine != "new-name" || value.Data.Profile != "personal" || value.Data.ShellMode != manifest.ShellModern {
		t.Fatalf("unexpected reconciled identity: %#v", value.Data)
	}
	if !value.Data.Applications["git"] || value.Data.Applications["zsh"] || value.Data.Applications["removed"] {
		t.Fatalf("unexpected reconciled applications: %#v", value.Data.Applications)
	}
	if !reflect.DeepEqual(value.Data.Packages["windows"], []string{"Git.Git"}) {
		t.Fatalf("unexpected packages: %#v", value.Data.Packages)
	}
}

func TestRefreshManifestDataSeparatesDesktopPackages(t *testing.T) {
	value := Config{Data: MachineData{Applications: map[string]bool{"git": true, "wezterm": true}}}
	RefreshManifestData(&value, definitions())
	if !reflect.DeepEqual(value.Data.Packages["darwin"], []string{"git"}) ||
		!reflect.DeepEqual(value.Data.Packages["darwinDesktop"], []string{"wezterm"}) {
		t.Fatalf("unexpected package groups: %#v", value.Data.Packages)
	}
}

func TestDisabledApplicationOwnsIgnoredConfigAndExactVersionedPackage(t *testing.T) {
	definitions := manifest.Manifest{Applications: []manifest.Application{
		{ID: "editor", Label: "Editor", Packages: map[string]string{"darwin": "editor"}, ConfigPaths: []string{".config/editor", ".config/editor/**"}},
	}}
	value := Config{Data: MachineData{
		Applications: map[string]bool{"editor": false},
		Versions:     map[string]string{"editor": "2.4.1"},
	}}
	RefreshManifestData(&value, definitions)
	if !slices.Equal(value.Data.IgnoredApplicationPaths, []string{".config/editor", ".config/editor/**"}) {
		t.Fatalf("unexpected ignored config paths: %#v", value.Data.IgnoredApplicationPaths)
	}
	value.Data.Applications["editor"] = true
	RefreshManifestData(&value, definitions)
	if got := value.Data.PackageSpecs["darwin"]; len(got) != 1 || got[0].Version != "2.4.1" {
		t.Fatalf("unexpected package specs: %#v", got)
	}
}
