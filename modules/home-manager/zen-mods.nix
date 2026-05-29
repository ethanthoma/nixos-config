# Advanced Tab Groups mod for Zen. The fx-autoconfig loader is injected into the
# zen-browser package (see _lib/zen-with-autoconfig.nix); this places the profile
# side: chrome/utils (loader), the mod's .uc.js, and its CSS via userChrome.css.
{ inputs, ... }:
{
  flake.homeManagerModules.zen-mods =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      chromeSrc = pkgs.runCommand "zen-atg-chrome" { } ''
        mkdir -p $out/utils $out/JS
        cp ${inputs.fx-autoconfig}/profile/chrome/utils/* $out/utils/
        cp ${inputs.advanced-tab-groups}/advanced-tab-groups.uc.js $out/JS/
        cp ${inputs.advanced-tab-groups}/userChrome.css $out/atg.css
      '';

      awk = "${pkgs.gawk}/bin/awk";
      grep = "${pkgs.gnugrep}/bin/grep";
    in
    {
      home.activation.zenMods = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        zendir="${config.home.homeDirectory}/.zen"
        ini="$zendir/profiles.ini"

        if [ ! -f "$ini" ]; then
          mkdir -p "$zendir/Default"
          cat > "$ini" <<'EOF'
        [Profile0]
        Name=Default (alpha)
        IsRelative=1
        Path=Default
        Default=1

        [General]
        StartWithLastProfile=1
        Version=2
        EOF
        fi

        prof=$(${awk} -F= '/^\[Install/{i=1} i&&/^Default=/{print $2; exit}' "$ini")
        if [ -z "$prof" ]; then prof=$(${awk} -F= '/^\[Profile/{p=1;d=0;path=""} p&&/^Path=/{path=$2} p&&/^Default=1/{d=1} p&&d&&path{print path; exit}' "$ini"); fi
        if [ -z "$prof" ]; then prof=$(${awk} -F= '/^Path=/{print $2; exit}' "$ini"); fi

        chrome="$zendir/$prof/chrome"
        mkdir -p "$chrome/JS"

        rm -rf "$chrome/utils"
        ln -s ${chromeSrc}/utils "$chrome/utils"
        ln -sfn ${chromeSrc}/JS/advanced-tab-groups.uc.js "$chrome/JS/advanced-tab-groups.uc.js"
        ln -sfn ${chromeSrc}/atg.css "$chrome/atg.css"

        uc="$chrome/userChrome.css"
        if ! { [ -f "$uc" ] && ${grep} -qF '"atg.css"' "$uc"; }; then
          { echo '@import "atg.css";'; [ -f "$uc" ] && cat "$uc" || true; } > "$uc.tmp"
          mv "$uc.tmp" "$uc"
        fi

        userjs="$zendir/$prof/user.js"
        b="// >>> zen-mods (managed by nixos) >>>"
        e="// <<< zen-mods (managed by nixos) <<<"
        if [ -f "$userjs" ]; then
          ${awk} -v b="$b" -v e="$e" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$userjs" > "$userjs.tmp"
        else
          : > "$userjs.tmp"
        fi
        {
          echo "$b"
          echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
          echo 'user_pref("browser.tabs.groups.enabled", true);'
          echo 'user_pref("browser.tabs.groups.arc-style", true);'
          echo "$e"
        } >> "$userjs.tmp"
        mv "$userjs.tmp" "$userjs"
      '';
    };
}
