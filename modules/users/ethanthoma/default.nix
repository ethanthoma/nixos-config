{ config, pkgs, username, ... }:

{
	imports = [
#		../../modules/apps/neovim
	];

	home = 
	let
		username = "ethanthoma";
	in {
		inherit username;

		homeDirectory = "/home/${username}";
		stateVersion = "23.05";

		packages = with pkgs; [
			wget
			zip
		];
	};

	programs.home-manager.enable = true;
}

