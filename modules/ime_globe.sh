# Hide the globe (IME switcher) icon in the keyboard's bottom row: transparent icon, the button
# itself stays tappable. Usage: hide | default | status
exec sh /data/local/tmp/patch_overlay.sh ime_globe "$1"
