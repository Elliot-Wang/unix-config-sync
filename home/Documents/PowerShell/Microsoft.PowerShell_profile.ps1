# Managed by unix-sync + chezmoi.

$env:EDITOR = "nvim"

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias vim nvim
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza --icons --long --header @args }
    function la { eza --icons --all @args }
}
