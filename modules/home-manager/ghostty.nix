{ ... }:
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

          theme = Rose Pine

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
