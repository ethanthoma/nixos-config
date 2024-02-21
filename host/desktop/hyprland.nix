{ pkgs, inputs, ... }:

{
	nix.settings = {
		experimental-features = [ "nix-command" "flakes" ];

		substituters = [
			"https://hyprland.cachix.org"
		];

		trusted-public-keys = [
			"hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
		];
	};

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

	programs.hyprland = {
		enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
        xwayland.enable = true;
	};

	services.dbus.enable = true;
	xdg.portal = {
		enable = true;
		extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
	};

    programs.dconf.enable = true;

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
