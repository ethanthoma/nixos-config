{ config, pkgs, ... }:

{
	networking.hostName = "desktop";

	imports = [
		./hardware.nix
        ../../apps/moonlander
	];

	time.timeZone = "America/Vancouver";

	system.stateVersion = "23.05";
}

