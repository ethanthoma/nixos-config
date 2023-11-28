{ config, pkgs, ... }:

{
	networking.hostName = "laptop";

	imports = [ ];

	time.timeZone = "America/Vancouver";

	system.stateVersion = "23.05";
}

