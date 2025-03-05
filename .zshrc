# antigen
source ~/.antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Load the theme.
antigen theme ys

# atuin
# antigen bundle atuinsh/atuin@main
# forgit
antigen bundle wfxr/forgit
# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions

# Tell Antigen that you're done.
antigen apply

# custom config
find $HOME/.zsh/ -name '*.zsh' -type f -print0 2> /dev/null |  while read -d $'\0' file; do source $file; done

if [ $TERM = 'xterm' ] && [ -e /usr/share/terminfo/x/xterm-256color ]; then
    export TERM='xterm-256color'
elif [ $TERM = 'screen' ] && [ -e /usr/share/terminfo/s/screen-256color ]; then
    export TERM='screen-256color'
elif [ $TERM = 'tmux' ] && [ -e /usr/share/terminfo/t/tmux-256color ]; then
    export TERM='tmux-256color'
fi

function ranger () { command ranger "$@"; echo -e "\e[?25h"; }

# My Config
# async-prompt is experimental feature and disabled for stable
zstyle ':omz:alpha:lib:git' async-prompt no

if which neofetch > /dev/null 2>&1; then
    alias neo="neofetch"
    if [ ! $TERM_PROGRAM = 'vscode' ]; then
        neofetch
    fi
fi

if which ranger > /dev/null 2>&1; then
    alias ra="ranger"
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

if which pyenv > /dev/null 2>&1; then eval "$(pyenv init -)"; fi
if which pyenv-virtualenv-init > /dev/null 2>&1; then eval "$(pyenv virtualenv-init -)"; fi
