if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd="fdfind"
fi

if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons --sort=ext"
  alias la="eza --icons --sort=ext --all"
  alias ll="eza --icons --sort=ext --long --header"
  alias lla="eza --icons --sort=ext --long --header --all"
  alias lt="eza --icons --sort=ext --tree --level=3 --color=always"
  alias ltd="eza --icons --sort=ext --tree --level=3 -D --color=always"
  alias llt="eza --icons --sort=ext --tree --level=3 --long --header --color=always"
elif command -v exa >/dev/null 2>&1; then
  alias ls="exa --icons --sort=ext"
  alias la="exa --icons --sort=ext --all"
  alias ll="exa --icons --sort=ext --long --header"
  alias lla="exa --icons --sort=ext --long --header --all"
fi

if command -v curlie >/dev/null 2>&1; then
  alias curl="curlie";
fi

if command -v lazygit >/dev/null 2>&1; then
  alias lg="lazygit"
fi

if command -v nvim >/dev/null 2>&1; then
  alias vim="nvim"
fi

if command -v bat >/dev/null 2>&1; then
  alias cat="bat"
  export BAT_THEME="OneHalfDark"
  # a colorizing pager for man
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"

  # global aliases to override --help
  #alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

  # you can do $ help cp or $ help git commit
  alias bathelp='bat --plain --language=help'
  help() {
      "$@" --help 2>&1 | bathelp
  }
fi

if command -v zoxide >/dev/null 2>&1; then
  # https://github.com/anthropics/claude-code/issues/2632
  if [[ "${CLAUDECODE:-}" != "1" ]]; then
    # When set to 1, z will print the matched directory before navigating to it
    export _ZO_ECHO="1"
    eval "$(zoxide init zsh)"
    alias cd="z"
  fi
fi

if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi


# Set up fzf key bindings and fuzzy completion
# source <(fzf --zsh)

# Setting fd as the default source for fzf
# export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS:-}'
  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626
  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'

# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# Print tree structure in the preview window
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"
# Options to fzf command
export FZF_COMPLETION_OPTS='--border --info=inline'

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}
export FORGIT_FZF_DEFAULT_OPTS="--exact --border --cycle --reverse --height '80%'"

if [[ -n "${HOMEBREW_PREFIX:-}" && -f "$HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh"
fi

function fvim() {
    rg --color=always --line-number --no-heading --smart-case "${*:-}" |
      fzf --ansi \
          --color "hl:-1:underline,hl+:-1:underline:reverse" \
          --delimiter : \
          --preview 'bat --color=always {1} --highlight-line {2}' \
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
          --bind 'enter:become(vim {1} +{2})'
}
