ranger_zoxid() {
    if ! which ranger > /dev/null; then
        echo ranger not installed
        return
    fi
    test -d ~/.config/ranger/plugins/zoxide || git clone https://github.com/jchook/ranger-zoxide.git ~/.config/ranger/plugins/zoxide
    echo ranger_zoxid installed!
}

ranger_devicons() {
    if ! which ranger > /dev/null; then
        echo ranger not installed
        return
    fi
    test -d ~/.config/ranger/plugins/ranger_devicons || git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons
    test -f ~/.config/ranger/rc.conf || ranger --copy-config=rc
    grep -q default_linemode ~/.config/ranger/rc.conf || echo "default_linemode devicons" >> ~/.config/ranger/rc.conf
    echo ranger_devicons installed!
}

echo Want to install plugins?
echo 1. ranger-zoxide
echo 2. ranger-devicons
echo ""

read opt

case $opt in
    1)
        ranger_zoxid
        ;;
    2)
        ranger_devicons
        ;;
    *)
        echo Quit.
        exit 1
        ;;
esac
