{ config, hyprland, lib, pkgs, ... }:

{
	imports = [
		./environment.nix
		hyprland.nixosModules.default
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

	programs.hyprland = {
		enable = true;
		enableNvidiaPatches = true;
		xwayland.enable = true;
	};

	services.dbus.enable = true;
	xdg.portal = {
		enable = true;
		extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
	};
}

