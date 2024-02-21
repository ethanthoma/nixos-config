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
            config.nvidia.acceptLicense = true; 
        };

		inherit (nixpkgs) lib;
	in {
		nixosConfigurations = {
			"desktop" = lib.nixosSystem {
				inherit system pkgs;

				specialArgs = { inherit inputs; };

				modules = [
					./host/desktop
                    {
						users.users.ethanthoma = {
							isNormalUser = true;
							extraGroups = [ "networkmanager" "wheel" ];
						};
						services.getty.autologinUser = "ethanthoma";
					}
				];
			};
		};

		homeConfigurations = {
			"ethanthoma" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;

                lib = nixpkgs.lib // home-manager.lib;

				modules = [ ./ethanthoma ];
			};
		};
	};
}

