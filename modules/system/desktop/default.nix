{ config, lib, pkgs, inputs, hyprland, ... }:

{
	imports = [
		./environment.nix
	];

	nix.settings = {
		experimental-features = [ "nix-command" "flakes" ];

		substituters = [
			"https://hyprland.cachix.org"
		];

		trusted-public-keys = [
			"hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
		];
	};

	services.xserver.enable = false;

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

	programs.zsh = {
		enable = true;
		oh-my-zsh.enable = true;
	};

	



	programs.hyprland = {
		enable = true;
		enableNvidiaPatches = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
        xwayland.enable = true;
	};

	services.dbus.enable = true;
	xdg.portal = {
		enable = true;
#		extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
	};

    programs.dconf.enable = true;
}

