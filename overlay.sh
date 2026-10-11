# Shared logic of the overlay modules: overlay.sh <module> <variant|default|revert|status>
# <variant> installs patch_<module>_<variant>.apk (pushed by patch.cmd), default removes it.
# RRO overlays persist across reboot.
p=gboardblank.$1
apk=/data/local/tmp/patch_$1_$2.apk
off() { pm list packages $p | sed 's/^package://' | while read -r x; do pm uninstall "$x" >/dev/null; done; }
# OMS registers a fresh overlay asynchronously; enable right after install can fail
en() { for i in 1 2 3 4 5; do cmd overlay enable --user 0 $1 2>/dev/null && return; sleep 1; done; cmd overlay enable --user 0 $1; }
# a running keyboard keeps the old resources; restart it so the change shows now
refresh() { am force-stop "$(settings get secure default_input_method | cut -d/ -f1)"; }
case "$2" in
  default|revert) off; echo "$1: default"; refresh ;;
  status) cmd overlay list android | grep $p || echo "$1: default" ;;
  *) [ -f "$apk" ] || { echo "$1: unknown action '$2' (see modules/$1.sh)"; exit 1; }
     off; pm install -r --bypass-low-target-sdk-block "$apk" >/dev/null &&
       en "$(pm list packages $p | sed 's/^package://')" && echo "$1: $2"; refresh ;;
esac
