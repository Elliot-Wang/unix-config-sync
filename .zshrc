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
# 没有匹配项的时候会报错，先注释掉
# for i in ~/.zsh/*.zsh ; do
#     if [ -r "$i" ]; then
#         . "$i"
#     fi
# done

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
alias ra="ranger"
neofetch

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
