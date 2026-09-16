{ ... }:
{
  flake.nixosModules.hyprland =
    { lib, pkgs, ... }:
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

        pkgs.libnotify
        pkgs.awww
        pkgs.cliphist
        pkgs.wl-clipboard
      ];

      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # systemd ships `D /tmp/.X11-unix 1777 root root 1h`, and `D` plus
      # `--remove` empties the directory. Every nixos-rebuild switch runs
      # systemd-tmpfiles-resetup with `--remove`, which unlinks the running
      # Xwayland's socket while it keeps listening, so every X11 client fails
      # with "unable to open display" until the next login. Boot still sweeps
      # via systemd-tmpfiles-setup.service, which keeps `--remove`.
      systemd.services.systemd-tmpfiles-resetup.serviceConfig.ExecStart =
        lib.mkForce "systemd-tmpfiles --create --exclude-prefix=/dev";

      services.dbus.enable = true;
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common = {
          default = [
            "hyprland"
            "gtk"
          ];
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
