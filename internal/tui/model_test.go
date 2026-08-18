package tui

import (
	"strings"
	"testing"

	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"

	"github.com/Elliot-Wang/unix-config-sync/internal/config"
	"github.com/Elliot-Wang/unix-config-sync/internal/lifecycle"
	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
)

func testModel() *Model {
	definitions := manifest.Manifest{
		SchemaVersion: 1,
		Applications: []manifest.Application{
			{ID: "git", Label: "Git", Description: "version control system", Required: true, Packages: map[string]string{"darwin": "git"}},
			{ID: "eza", Label: "eza", Description: "alternative to ls", Packages: map[string]string{"darwin": "eza"}},
		},
		Profiles: []manifest.Profile{
			{ID: "personal", Label: "Personal", ShellMode: manifest.ShellModern, Applications: []string{"eza"}},
			{ID: "server", Label: "Server", ShellMode: manifest.ShellLegacy},
		},
	}
	info := platform.Info{OS: "darwin", OSID: "darwin", Arch: "arm64", Hostname: "mac"}
	value := config.Default(info, "/tmp/dotfiles", definitions)
	return New(value, definitions, info)
}

func TestToggleApplication(t *testing.T) {
	m := testModel()
	if !m.config.Data.Applications["eza"] {
		t.Fatal("expected application to start enabled")
	}
	m.move(1)
	updated, _ := m.Update(tea.KeyPressMsg(tea.Key{Code: ' '}))
	got := updated.(*Model)
	if got.config.Data.Applications["eza"] {
		t.Fatal("expected space to disable application")
	}
}

func TestRequiredApplicationCannotToggle(t *testing.T) {
	m := testModel()
	if marker := m.marker(m.choices[0]); marker != "[*]" {
		t.Fatalf("required marker = %q, want [*]", marker)
	}
	updated, _ := m.Update(tea.KeyPressMsg(tea.Key{Code: ' '}))
	got := updated.(*Model)
	if !got.config.Data.Applications["git"] {
		t.Fatal("required application was disabled")
	}
}

func TestApplicationCommentIsRenderedInline(t *testing.T) {
	view := testModel().render()
	if !strings.Contains(view, "-- version control system") {
		t.Fatalf("application comment is not inline:\n%s", view)
	}
}

func TestNextProfileAppliesApplicationDefaultsAndShellMode(t *testing.T) {
	m := testModel()
	updated, _ := m.Update(tea.KeyPressMsg(tea.Key{Code: 'p', Text: "p"}))
	got := updated.(*Model)
	if got.config.Data.Profile != "server" || got.config.Data.ShellMode != manifest.ShellLegacy || got.config.Data.Applications["eza"] || !got.config.Data.Applications["git"] {
		t.Fatalf("unexpected profile state: %#v", got.config.Data)
	}
}

func TestEditApplicationVersion(t *testing.T) {
	m := testModel()
	m.move(1)
	m.Update(tea.KeyPressMsg(tea.Key{Code: 'v', Text: "v"}))
	m.Update(tea.KeyPressMsg(tea.Key{Code: 'u', Mod: tea.ModCtrl}))
	for _, character := range "0.23.5" {
		m.Update(tea.KeyPressMsg(tea.Key{Code: character, Text: string(character)}))
	}
	m.Update(tea.KeyPressMsg(tea.Key{Code: tea.KeyEnter}))
	if got := m.config.Version("eza"); got != "0.23.5" {
		t.Fatalf("desired version = %q", got)
	}
}

func TestRemoveActionRequiresConfirmation(t *testing.T) {
	m := testModel()
	m.Update(tea.KeyPressMsg(tea.Key{Code: 'x', Text: "x"}))
	if m.confirming != lifecycle.ModeRemove {
		t.Fatalf("confirming = %q", m.confirming)
	}
	m.Update(tea.KeyPressMsg(tea.Key{Code: 'y', Text: "y"}))
	if result := m.Result(); result.Action != lifecycle.ModeRemove || result.Canceled {
		t.Fatalf("unexpected result: %#v", result)
	}
}

func TestApplicationScreenFitsEightyColumns(t *testing.T) {
	m := testModel()
	m.width = 80
	m.height = 24
	for _, line := range strings.Split(m.render(), "\n") {
		if width := ansi.StringWidth(line); width > 80 {
			t.Fatalf("rendered line is %d columns wide: %q", width, line)
		}
	}
}
