# antigen
source ~/.antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Load the theme.
antigen theme ys

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
alias neo="neofetch"
alias ra="source ranger"

if [ ! $TERM_PROGRAM = 'vscode' ]; then
    neofetch
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fpath=(~/.zsh/_cht $fpath)

export MVN_HOME="/Users/mac/Opt/apache-maven-3.6.3"
export PATH="$MVN_HOME/bin:$PATH"
export PATH="/usr/local/opt/mysql-client@5.7/bin:$PATH"
