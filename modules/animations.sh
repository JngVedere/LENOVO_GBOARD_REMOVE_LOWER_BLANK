# Animation scale 0.5x (persists across reboot)
keys="window_animation_scale transition_animation_scale animator_duration_scale"
case "$1" in
  apply)  v=0.5 ;;
  revert) v=1 ;;
  status) for k in $keys; do echo "$k=$(settings get global $k)"; done; exit 0 ;;
  *) echo "usage: apply|revert|status"; exit 1 ;;
esac
for k in $keys; do settings put global $k $v; done
