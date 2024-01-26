{ lib, pkgs, ... }:

let 
	username = "ethanthoma";
	homeDirectory = "/home/${username}";
in {
	imports = [
        ./apps
		./rice
	];

    hm-apps = { inherit username homeDirectory; };

	home = let
		mkMutableConfig = import ./mutable-config.nix { inherit pkgs lib homeDirectory; };
	in {
		inherit username homeDirectory;

		stateVersion = "23.05";

		activation = {
			nvim-config = mkMutableConfig {
				name = "nvim-config";
				repoUrl = "https://github.com/ethanthoma/neovim-config.git";
				configPath = ".config/nvim";
			};
		};
	};

	programs.bash = {
		enable = true;
		bashrcExtra = ''
			mkdir -p ${homeDirectory}/.config

			# rip (rm improved)
			export GRAVEYARD=${homeDirectory}/.config/rip/graveyard

			alias cat='bat'
			alias find='fd'
		'';
	};

	programs.home-manager.enable = true;
}
