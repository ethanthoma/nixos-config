{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        grim
        slurp
        imagemagick
    ];

    services.greetd = {
        enable = true;
        settings = rec {
            initial_session = {
                command = "${pkgs.hyprland}/bin/Hyprland";
                user = "ethanthoma";
            };
            default_session = initial_session;
        };
    };

	programs = {
        hyprland = {
            enable = true;
            xwayland.enable = true;
        };

        dconf.enable = true;
	};

	services.dbus.enable = true;
	xdg.portal = {
		enable = true;
		extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
	};

	environment.sessionVariables = {
		WLR_NO_HARDWARE_CURSORS = "1";
		NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        XDG_SESSION_TYPE = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = "1";
        CLUTTER_BACKEND = "wayland";
        WLR_RENDERER = "vulkan";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        GTK_USE_PORTAL = "1";
        NIXOS_XDG_OPEN_USE_PORTAL = "1";
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
        ENABLE_VKBASALT = "1";
    };
}
