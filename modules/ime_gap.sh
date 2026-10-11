# Height of the keyboard's bottom button row (collapse / globe), in dp. Android 17+.
# Usage: <dp 0-120> | default | status. 32 = minimum that keeps the buttons usable;
# on tablets with a taskbar, values below 32 don't move the keyboard any lower.
sh /data/local/tmp/patch_overlay.sh ime_gap "$1" || exit
[ "$1" != status ] || echo "effective: $(cmd overlay lookup android android:dimen/input_method_navigation_bar_height)"
