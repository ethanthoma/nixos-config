{ ... }:
{
  flake.nixosModules.hyprland =
    { pkgs, ... }:
    {
      services.greetd = {
        enable = true;
        settings = rec {
          initial_session = {
            command = "start-hyprland";
            user = "ethanthoma";
          };
          default_session = initial_session;
        };
      };

      environment.systemPackages = [
        pkgs.grim
        pkgs.slurp
        pkgs.imagemagick

        pkgs.mako
        pkgs.libnotify
        pkgs.swww
        pkgs.fuzzel
        pkgs.cliphist
        pkgs.wl-clipboard
      ];

      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      services.dbus.enable = true;
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common = {
          default = [ "hyprland" "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        };
      };

      programs.dconf.enable = true;

      environment.sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        XDG_SESSION_TYPE = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = "1";
        CLUTTER_BACKEND = "wayland";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        GTK_USE_PORTAL = "1";
        NIXOS_XDG_OPEN_USE_PORTAL = "1";
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
        ENABLE_VKBASALT = "1";
      };
    };
}
