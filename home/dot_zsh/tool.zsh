alias ola="ollama"
alias ccp="claude --dangerously-skip-permissions"
alias occp="ollama launch claude --model glm-5.1:cloud -- --dangerously-skip-permissions"
alias tx="tmux -u"

function fsub() {
    sort -- "$1" "$2" "$2" | uniq -u
}

function funi() {
    sort -- "$1" "$2" | uniq
}

function fint() {
    sort -- "$1" "$2" | uniq -d
}
