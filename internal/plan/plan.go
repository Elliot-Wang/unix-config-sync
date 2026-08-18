package plan

import (
	"fmt"
	"slices"

	"github.com/Elliot-Wang/unix-config-sync/internal/config"
	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
)

type Action string

const (
	Apply   Action = "APPLY"
	Ignore  Action = "IGNORE"
	Install Action = "INSTALL"
)

type Item struct {
	Action Action
	Target string
	Detail string
}

func Resolve(value config.Config, definitions manifest.Manifest, info platform.Info) []Item {
	items := ResolveConfig(value, info)
	items = slices.Grow(items, len(definitions.Applications))

	for _, application := range definitions.Applications {
		if !application.Supports(info.OSID, info.Family()) {
			continue
		}
		enabled := value.Data.Applications[application.ID]
		action := Ignore
		if enabled {
			action = Install
		}
		packageName, _ := application.Package(info.OSID, info.Family())
		detail := packageName
		if application.Kind == "bootstrap" {
			detail = "bootstrap prerequisite"
		} else if manager := info.PackageManager(); manager != "" {
			detail = fmt.Sprintf("%s via %s", packageName, manager)
		}
		if application.Required {
			detail = "required · " + detail
		}
		items = append(items, Item{Action: action, Target: application.Label, Detail: detail})
	}
	return items
}

func ResolveConfig(value config.Config, info platform.Info) []Item {
	items := make([]Item, 0, 6)
	if info.OS == "windows" {
		items = append(items, enabledItem(true, "PowerShell profile", "common proxy helpers and shell mode"))
	} else {
		items = append(items,
			enabledItem(value.Data.Applications["zsh"], "~/.zshrc", "common proxy helpers and shell configuration"),
			enabledItem(value.Data.Applications["tmux"], "~/.tmux.conf", "tmux configuration"),
		)
		modernShell := value.Data.Applications["zsh"] && value.Data.ShellMode == manifest.ShellModern
		items = append(items, enabledItem(modernShell, "Modern shell aliases", "shellMode="+value.Data.ShellMode))
	}
	items = append(items, enabledItem(value.Data.Applications["neovim"], "Neovim configuration", "application-managed configuration"))
	if info.OS != "windows" {
		items = append(items,
			enabledItem(value.Data.Applications["vim"], "Vim configuration", "application-managed configuration"),
			enabledItem(value.Data.Applications["ranger"], "Ranger configuration", "application-managed configuration"),
		)
	}

	return items
}

func enabledItem(enabled bool, target, detail string) Item {
	action := Ignore
	if enabled {
		action = Apply
	}
	return Item{Action: action, Target: target, Detail: detail}
}
