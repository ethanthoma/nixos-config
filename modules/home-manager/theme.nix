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
        theme = {
          name = "rose-pine";
          package = pkgs.rose-pine-gtk-theme;
        };
        cursorTheme = {
          name = "rose-pine-cursor";
          package = pkgs.rose-pine-cursor;
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      };
    };
}
