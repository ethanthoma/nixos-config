{
	description = "A very basic flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		hyprland.url = "github:hyprwm/Hyprland";
	};

	outputs = { self, nixpkgs, home-manager, hyprland, ... } @ inputs : 
	let
		system = "x86_64-linux";

		pkgs = import nixpkgs {
			inherit system;
			config.allowUnfree = true;
			overlays = [];
		};

		inherit (nixpkgs) lib;

		mkHost = opts:
			{ pkgs, ...}:
			{

				imports = [
					#./modules/hosts/${opts.hostname}
					./configuration.nix
					./modules/system/boot
					./modules/system/desktop
					./modules/system/sound
				] ++
				(lib.optional opts.touchpad.enable ./modules/system/touchpad);
			};
	in {
		nixosConfigurations = {
			"laptop" = mkHost {
				hostname = "laptop";
				touchpad.enable = true;
			};
			"desktop" = lib.nixosSystem {
				inherit system pkgs;

				specialArgs = inputs;

				modules = [
					./modules/system/boot
					./modules/system/desktop
					./modules/system/networking
					./modules/system/sound
						
					./modules/apps/neovim

					./modules/hosts/desktop

					{
						users.users.ethanthoma = {
							isNormalUser = true;
							extraGroups = [ "networkmanager" "wheel" ];
							packages = with pkgs; [
								networkmanagerapplet
								firefox-wayland
								tree
								kitty
								tmux
								mako
								git
								libnotify
								gh
								swww
								fuzzel
								discord
							];
						};
						services.getty.autologinUser = "ethanthoma";
					}
				];
			};
		};

		homeManagerConfigurations = {
			"ethanthoma" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;

				modules = [
					./modules/users/ethanthoma
					./modules/apps/neovim
				];
			};
		};
	};
}

