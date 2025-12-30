# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Unix configuration synchronization repository that manages dotfiles and configurations for Vim, Neovim, Zsh, and various CLI tools across Linux, macOS, and Windows platforms.

## Key Commands

### Initial Setup
```bash
./init.sh          # Install and configure all tools (vim, zsh, neofetch, ranger)
./plugin.sh        # Install additional plugins
```

### Configuration Sync
```bash
./sync.zsh save    # Copy configs from home directory to repo
./sync.zsh update  # Copy configs from repo to home directory
./sync.zsh diff    # Show differences between configs
./sync.zsh debug   # Debug mode - show what would be copied
```

### Git Workflow
```bash
./save.sh [msg]    # Save configs to repo and commit (use "ts" for timestamp)
./update.sh        # Pull from remote and update local configs
```

## Architecture

### Config Sync System

The core sync mechanism is in `sync.zsh`, which provides bidirectional sync between system configs and the repository:

- **Managed Files**: `.vimrc`, `.zshrc`, neofetch config, oh-my-zsh git plugin
- **Platform-specific**: macOS configs stored in `.zsh/alter.zsh.mac`
- **Sync Logic**: Uses `cmp` to detect changes before prompting for updates

### Directory Structure

```
.
├── vim/              # Vim plugins and color schemes (onedark.vim, vim-plug)
├── nvim/             # Neovim config from jdhao/nvim-config (Lua-based)
│   └── lua/          # Plugin specs, mappings, autocmds, utils
├── zsh/              # Zsh plugins (antigen, oh-my-zsh git plugin)
├── .zsh/             # Custom zsh scripts (sourced automatically)
│   ├── alter.zsh.mac # macOS tool aliases (bat, exa, zoxide, yazi)
│   ├── proxy.zsh     # Proxy configuration
│   └── fzf.zsh       # FZF configuration and integrations
├── ranger/           # Ranger file manager config
├── neofetch/         # Neofetch system info display config
├── .vimrc            # Vim configuration
├── .zshrc            # Zsh configuration (antigen-based)
├── git_func.zsh      # Git helper functions (fshow, fbr, fco_preview)
└── sync.zsh          # Bidirectional config sync tool
```

### Zsh Configuration

- **Plugin Manager**: Antigen (loads oh-my-zsh, forgit, syntax highlighting, autosuggestions)
- **Custom Scripts**: All `.zsh` files in `~/.zsh/` are auto-sourced on shell start
- **Theme**: ys (from oh-my-zsh)

### Tool Replacements (macOS via alter.zsh.mac)

Modern CLI tools replacing traditional Unix commands:
- `ls` → `exa` (with icons, sorting by extension)
- `cat` → `bat` (syntax highlighting, paging)
- `cd` → `z` via `zoxide` (smart directory jumping)
- `curl` → `curlie` (better formatting)
- `vim` → `nvim` (if available)
- `ranger` → `yazi` (function wrapper with cwd tracking)

### Git Functions (git_func.zsh)

- `fshow`: Interactive git log browser with commit preview (fzf)
- `fbr`: Fuzzy branch checkout (last 30 branches, sorted by recent commit)
- `fco_preview`: Checkout with commit preview between branch and HEAD

### Vim Configuration

- **Plugin Manager**: vim-plug
- **Theme**: onedark
- **Key Features**: Auto-save on InsertLeave/FocusLost, session management, fold persistence, ripgrep integration
- **File-specific indentation**: JS/TS/HTML/CSS/YAML (2 spaces), Python (4 spaces)

### Neovim Configuration

Based on jdhao/nvim-config:
- **Plugin Manager**: lazy.nvim
- **LSP**: nvim-lspconfig
- **Completion**: nvim-cmp
- **File Navigation**: LeaderF, nvim-tree.lua
- **Git**: vim-fugitive
- **Treesitter**: Syntax highlighting
- **Leader Key**: `,` (comma)

## Platform Detection

All scripts detect OS via `uname` and handle platform-specific logic:
- `Darwin` = macOS
- `redhat` = RHEL/CentOS (detected via `/etc/redhat-release`)
- `debian` = Debian/Ubuntu (detected via `/etc/debian_version`)

## Notes

- The nvim config is a copy of jdhao's comprehensive setup (maintained for Neovim 0.10.2+)
- Config sync is interactive - prompts before overwriting files
- macOS-specific configs are separated to prevent Linux/Windows conflicts
- All custom zsh functions and aliases are auto-loaded from `~/.zsh/` directory
