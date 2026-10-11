# Read-only diagnostics for developing modules (changes nothing).
echo "== system"
dumpsys package android 2>/dev/null | grep -m1 'signatures:' | grep -q b4addb29 && echo "platform key: AOSP test key (overlays supported)" || echo "platform key: NOT the AOSP test key (overlays unsupported)"
getprop | grep -iE 'pixelos|ro\.custom|ro\.build\.version\.(release|sdk|incremental)\]|ro\.product\.model'

echo "== ime / nav"
echo "navigation_mode=$(settings get secure navigation_mode)"
echo "ime=$(settings get secure default_input_method)"
dumpsys package com.google.android.inputmethod.latin 2>/dev/null | grep -m1 versionName
echo "-- overlays"
cmd overlay list | grep -iE 'navbar|gestur|ime|keyboard|launcher|taskbar|hint'
echo "-- settings"
for ns in secure system global; do settings list $ns | grep -iE 'ime|keyboard|navbar|navigation|taskbar|hint' | sed "s/^/$ns: /"; done
