{
	description = "ethanthoma's nixos config";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		hyprland.url = "github:hyprwm/Hyprland";

        agenix = {
            url = "github:ryantm/agenix";
            inputs = {
                nixpkgs.follows = "nixpkgs";
                darwin.follows = "";
            };
        };
	};

	outputs = { self, nixpkgs, home-manager, hyprland, agenix, ... } @ inputs : 
	let
		system = "x86_64-linux";

		pkgs = import nixpkgs {
			inherit system;
			config.allowUnfree = true;
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
            "surface" = nixpkgs.lib.nixosSystem {
                inherit system pkgs;
                modules = [
                    ./host/surface
                ];
            };
		};

		homeConfigurations = let
            agenix-module = [
                agenix.homeManagerModules.default
                {
                    home.packages = [ agenix.packages.${system}.default ];
                }
            ];
        in {
			"ethanthoma" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;

				lib = nixpkgs.lib // home-manager.lib;

				modules = agenix-module ++ [ ./ethanthoma ];
			};
		};
	};
}

