{
	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable";

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { nixpkgs, home-manager, ... }: 
	let
		system = "x86_64-linux";
		
		pkgs = import nixpkgs {
			inherit system;
			config.allowUnfree = true;
		};
	in {
		nixosConfigurations = {
			"surface" = nixpkgs.lib.nixosSystem {
				inherit system pkgs;
				modules = [
					./host/surface
				];
			};
		};

		homeConfigurations = {
			"ethanthoma" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;

				lib = nixpkgs.lib // home-manager.lib;

				modules = [
					./ethanthoma
				];
			};
		};
	};
}
