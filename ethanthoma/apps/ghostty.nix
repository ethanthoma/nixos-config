{ pkgs, ... }:
{
  home.packages = [
    pkgs.ghostty
  ];

  home.file.".config/ghostty/config" = {
    source = pkgs.writeText "config" ''
      keybind = clear

      theme = rose-pine

      background-opacity = 0.75

      confirm-close-surface = false

      window-padding-balance = true
      window-padding-x = 4
      window-padding-y = 4,1
      window-decoration = false

      gtk-tabs-location = hidden

      keybind = unconsumed:ctrl+shift+c=copy_to_clipboard
      keybind = unconsumed:ctrl+v=paste_from_clipboard

      font-family = JetBrains Mono
      minimum-contrast = 3
    '';
  };
}
