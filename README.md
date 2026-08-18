# unix-sync

`unix-sync` is a terminal-only configuration synchronization UI. It uses [chezmoi](https://www.chezmoi.io/) for managed-file state and Git for repository state, while keeping the first screen strictly read-only.

It targets macOS, Windows, CentOS/RHEL-compatible Linux, and Debian-compatible Linux.

## Safest first run

From this repository, print a non-interactive report:

```sh
go run ./cmd/unix-sync --dry-run --source .
```

This command does not initialize the machine, change `$HOME`, fetch a remote, install packages, or write to the source repository. If no saved machine settings exist, it renders with temporary `personal` defaults and removes the temporary config afterward.

To open the full-screen sync UI:

```sh
go run ./cmd/unix-sync --source .
```

```text
 UNIX-SYNC  sync ───────────────────────────────────────────────
 atlas  darwin/arm64  profile=personal  shell=modern  READ-ONLY PREVIEW
 source /path/to/unix-config-sync
 mode   temporary defaults (nothing initialized)

 [1] STATUS   [2] DIFF   [3] REPOSITORY
 ──────────────────────────────────────────────────────────────
 Managed-file drift:

  M .zshrc
  M .config/nvim/init.lua

 Actions
   a apply source → home    c capture home → source    u pull + apply
   s settings   r refresh   tab switch view   q quit without changes
```

Opening the UI and switching views never changes files. `a`, `c`, and `u` first open a confirmation screen, then use chezmoi's interactive confirmation as a second guard.
Long status and diff output stays inside the TUI: use `↑`/`↓`, `j`/`k`, Page Up/Page Down, Home, or End to navigate. After an action, the dashboard reopens with a fresh snapshot and a completion notice.

## Synchronization directions

- `Apply`: repository source → managed files in `$HOME`.
- `Capture`: managed files in `$HOME` → repository source. It does not commit or push Git.
- `Update`: pull the source repository, recalculate, then apply interactively.
- `Repository`: shows local Git branch and worktree state independently from chezmoi drift.

The complete non-TUI commands are:

```sh
unix-sync --dry-run
unix-sync status
unix-sync diff
unix-sync apply --dry-run
unix-sync capture --dry-run
unix-sync update --dry-run
```

`update --dry-run` deliberately does not fetch the remote, because even a fetch changes local Git metadata. It reports the current local diff and states that remote changes were not inspected.

## Machine settings

Profiles, shell mode, and application selection are secondary to synchronization. Open them with:

```sh
unix-sync settings
```

Pressing Enter in settings is always **save only**: it writes `~/.config/unix-sync/chezmoi.json` and does not apply dotfiles or change installed applications. Package operations have separate keys, a visible Plan, and a confirmation step.

The settings model has one primary choice and one application list:

- `Profile` is the only environment-mode choice. It owns the shell mode: personal/work are Modern and server is Legacy. Shell mode cannot be changed independently.
- `Applications` is the platform-aware catalog. Optional applications can be toggled; required applications are visibly locked on.

Required applications are chezmoi and Git on every supported platform, Zsh + Oh My Zsh on Unix, and Homebrew on macOS. These requirements are direct policy flags, not a dependency graph.

Package delivery is not a feature switch. Every profile resolves its selected applications through brew, dnf/yum, apt-get, or winget. A confirmed dotfile `apply` can install missing selected packages through chezmoi `run_onchange` scripts. The settings TUI also exposes explicit application lifecycle actions:

```text
[*] Git             latest     missing      -- version control system
[x] Neovim          latest     0.11.5       -- modern terminal editor
[ ] WezTerm         latest     missing      -- GPU-accelerated terminal emulator

i reconcile desired state   u upgrade latest   x remove disabled
v edit desired version      enter save only
```

- `i` installs missing selected applications and converges exact-version policies.
- `u` upgrades only selected applications whose desired version is `latest`.
- `x` explicitly uninstalls disabled catalog applications. Removal never happens merely because Space disabled an application.
- `v` sets `latest` or an exact native package version. The Plan always shows desired, installed, available, and action before execution.

Repository `update` and application `upgrade` are intentionally different operations: the former pulls the config repository and applies managed files; the latter asks the native package manager to update selected applications.

Exact-version support follows the native manager. APT uses `package=version`, DNF/Yum uses its versioned package spec, and WinGet uses `--version`. Homebrew can install its current catalog version and pin an installed formula/cask, but arbitrary historical versions require a versioned formula or a maintained tap. An unsupported request is rejected before settings are saved or package commands run.

An application owns both its package and its config paths. Disabling it immediately adds its config paths to chezmoi's generated ignore set. A confirmed uninstall saves that disabled state before removing the package, so future syncs no longer manage the config. Existing files in the home directory are preserved. If an application was removed outside unix-sync, the Plan presents the absence as drift: leave it selected to reinstall it, or disable it to adopt the absence and stop syncing its config.

Proxy helpers are common configuration rather than a work-profile feature. Unix profiles receive `pxon`/`pxoff` in Zsh; Windows profiles receive equivalent PowerShell commands.

For automation:

```sh
unix-sync settings --source "$PWD" --profile server --non-interactive
```

Applications can also be changed explicitly:

```sh
unix-sync settings --enable-apps wezterm --disable-apps fastfetch --non-interactive
```

WezTerm is an optional cross-platform, GPU-accelerated terminal emulator in the same category as iTerm2 or Windows Terminal. It is not selected by default.

## Legacy `_*.zsh` rule

Files matching `**/_*.zsh` are always ignored by chezmoi. They remain loadable by `.zshrc`, but are never presented as a setting or synchronization policy. This preserves the original shell-era convention without making it part of the cross-platform domain model.

## Bootstrap

From a clone:

```sh
./bootstrap.sh
```

On Windows PowerShell:

```powershell
.\bootstrap.ps1
```

The bootstrap installs chezmoi, builds or downloads `unix-sync`, opens machine settings, then opens the read-only sync screen. In settings, Enter only saves; application installation requires the separate confirmed `i` action or a later confirmed dotfile apply.

## Repository model

Application policy is defined in [`.unix-sync.json`](.unix-sync.json):

- `applications` owns labels, platform package identifiers, desktop/application type, and the config paths managed with each application.
- `profiles` provides a default application set and one shell mode.
- machine-local settings retain selected applications and exact-version policies, then derive native package-manager input and ignored config paths from the catalog.

Vim, Neovim, Ranger, Zsh, and tmux configuration now follow their owning application. The old Neofetch source is retained as repository history but excluded from active synchronization; Fastfetch is the selected replacement application.

The chezmoi source state is [`home/`](home). Platform and application exclusions are resolved by [`home/.chezmoiignore`](home/.chezmoiignore).

```text
cmd/unix-sync/       CLI entry point
internal/syncui/     read-only-first synchronization TUI
internal/tui/         machine-settings TUI
internal/config/      temporary and saved chezmoi configs
internal/lifecycle/   installed/available version inspection and package actions
internal/manifest/    repository policy schema
internal/chezmoi/     guarded chezmoi adapter
internal/platform/    macOS, Windows, and Linux detection
home/                 chezmoi source-state directory
bootstrap.*           fresh-machine entry points
```

## Development

```sh
go test ./...
go vet ./...
go run ./cmd/unix-sync --dry-run --source .
```

Release tags build static binaries for macOS, Linux, and Windows on amd64 and arm64.
