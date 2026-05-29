# wraps zen-browser to inject the fx-autoconfig loader (config.js + defaults pref)
# into the program dir. firefox resolves its program dir from the real binary, so
# we full-copy the tree and rewrite the launcher's hardcoded exec path into $out.
{
  runCommand,
  zen,
  fx-autoconfig,
}:

runCommand "zen-browser-autoconfig" { } ''
  cp -r --no-preserve=mode,ownership ${zen} $out
  chmod -R u+w $out

  prog=$(echo $out/lib/zen-*)
  cp ${fx-autoconfig}/program/config.js "$prog/config.js"
  mkdir -p "$prog/defaults/pref"
  cp ${fx-autoconfig}/program/defaults/pref/config-prefs.js "$prog/defaults/pref/config-prefs.js"

  sed -i "s|${zen}/bin/.zen-wrapped|$out/bin/.zen-wrapped|g" "$out/bin/zen"
''
