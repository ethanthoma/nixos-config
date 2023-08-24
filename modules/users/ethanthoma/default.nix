{ config, pkgs, username, ... }:

{
	imports = [
		../../modules/apps/neovim
	];

	config.home = {
		inherit username;

		homeDirectory = "/home/${username}";
		stateVersion = "23.05";

		packages = with pkgs; [
			wget
			zip
		];
	};

	config.programs.home-manager.enable = true;
}

