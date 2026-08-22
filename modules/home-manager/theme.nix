{ ... }:
{
  flake.homeManagerModules.theme =
    { pkgs, ... }:
    {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };

      gtk = {
        enable = true;
        cursorTheme = {
          name = "rose-pine-cursor";
          package = pkgs.rose-pine-cursor;
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
        gtk4.theme = null;
      };
    };
}
