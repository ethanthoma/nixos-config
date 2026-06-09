{ ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.ghostty =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.ghostty
      ];

      home.file.".config/ghostty/config" = {
        source = pkgs.writeText "config" ''
          keybind = clear

          background = ${palette.base}
          foreground = ${palette.text}
          cursor-color = ${palette.gold}
          selection-background = ${palette.overlay}
          selection-foreground = #eeffff

          palette = 0=#000000
          palette = 1=${palette.love}
          palette = 2=${palette.leaf}
          palette = 3=${palette.gold}
          palette = 4=${palette.pine}
          palette = 5=${palette.iris}
          palette = 6=${palette.foam}
          palette = 7=#ffffff
          palette = 8=#464b5d
          palette = 9=${palette.love}
          palette = 10=${palette.leaf}
          palette = 11=${palette.gold}
          palette = 12=${palette.pine}
          palette = 13=${palette.iris}
          palette = 14=${palette.foam}
          palette = 15=#ffffff

          confirm-close-surface = false

          window-padding-balance = true
          window-padding-x = 4
          window-padding-y = 4,1
          window-decoration = false

          gtk-tabs-location = hidden

          keybind = unconsumed:ctrl+shift+c=copy_to_clipboard
          keybind = unconsumed:ctrl+v=paste_from_clipboard
          keybind = ctrl+shift+r=reload_config

          font-family = MonaspiceNe Nerd Font Mono
          font-size = 12
          minimum-contrast = 3
        '';
      };
    };
}
