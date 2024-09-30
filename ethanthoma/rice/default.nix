{ pkgs, ... }:

{
  imports = [ ./font.nix ];

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
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
  };
}
