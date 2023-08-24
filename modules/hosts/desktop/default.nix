{ config, pkgs, ... }:

{
	networking.hostName = "desktop";

	imports = [
		./hardware.nix
	];

	time.timeZone = "America/Vancouver";

	services.xserver.videoDrivers = [ 
		"nvidia"
	];

	system.stateVersion = "23.05";
}

