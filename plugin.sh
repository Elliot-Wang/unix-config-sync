ranger_zoxid() {
    test -d ~/.config/ranger/plugins/zoxide || git clone https://github.com/jchook/ranger-zoxide.git ~/.config/ranger/plugins/zoxide
    echo ranger_zoxid installed!
}

ranger_devicons() {
    test -d ~/.config/ranger/plugins/ranger_devicons || git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons
    grep -q default_linemode $HOME/.config/ranger/rc.conf || echo "default_linemode devicons" >> $HOME/.config/ranger/rc.conf
    echo ranger_devicons installed!
}

echo Want to install plugins?
echo 1. ranger-zoxide
echo ""

read opt

case $opt in
  1)
    ranger_zoxid
    ;;
  *)
    echo Quit.
    exit 1
    ;;
esac
