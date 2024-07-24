{
	description = "ethanthoma's nixos config";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, home-manager, ... } @ inputs : 
	let
		system = "x86_64-linux";

        username = "ethanthoma";

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

				specialArgs = { inherit inputs username; };

				modules = [
                    ./host/desktop
                    {
                        nix.settings = {
                            experimental-features = [ "nix-command" "flakes" ];
                        };
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

		homeConfigurations = {
			"${username}" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;

				lib = nixpkgs.lib // home-manager.lib;

				modules = [ 
                    ./ethanthoma 
                ];
			};
		};
	};
}

