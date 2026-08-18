package plan

import (
	"testing"

	"github.com/Elliot-Wang/unix-config-sync/internal/config"
	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
)

func TestResolveModernWorkstation(t *testing.T) {
	definitions := manifest.Manifest{
		Applications: []manifest.Application{
			{ID: "git", Label: "Git", Packages: map[string]string{"darwin": "git"}},
			{ID: "zsh", Label: "Zsh", Packages: map[string]string{"darwin": "zsh"}},
			{ID: "tmux", Label: "tmux", Packages: map[string]string{"darwin": "tmux"}},
			{ID: "neovim", Label: "Neovim", Packages: map[string]string{"darwin": "neovim"}},
		},
	}
	value := config.Config{Data: config.MachineData{
		Profile: "work", ShellMode: manifest.ShellModern,
		Applications: map[string]bool{"git": true, "zsh": true, "tmux": true, "neovim": true},
	}}
	items := Resolve(value, definitions, platform.Info{OS: "darwin", OSID: "darwin"})
	wanted := map[string]Action{
		"~/.zshrc": Apply, "~/.tmux.conf": Apply, "Modern shell aliases": Apply,
		"Neovim configuration": Apply, "Git": Install, "Zsh": Install,
	}
	for _, item := range items {
		if action, ok := wanted[item.Target]; ok && item.Action != action {
			t.Fatalf("%s action = %s, want %s", item.Target, item.Action, action)
		}
	}
}

func TestResolveLegacyServerIgnoresModernShell(t *testing.T) {
	definitions := manifest.Manifest{Applications: []manifest.Application{
		{ID: "zsh", Label: "Zsh", Packages: map[string]string{"rhel": "zsh"}},
	}}
	value := config.Config{Data: config.MachineData{
		Profile: "server", ShellMode: manifest.ShellLegacy, Applications: map[string]bool{"zsh": true},
	}}
	items := Resolve(value, definitions, platform.Info{OS: "linux", OSID: "linux-centos"})
	for _, item := range items {
		if item.Target == "Modern shell aliases" && item.Action != Ignore {
			t.Fatalf("modern shell action = %s", item.Action)
		}
	}
}
