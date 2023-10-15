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
	in {
		nixosConfigurations = {
			"desktop" = lib.nixosSystem {
				inherit system pkgs;

				specialArgs = { inherit inputs; };

				modules = [
					./modules/system/apps
					./modules/system/bluetooth
					./modules/system/boot/systemd
					./modules/system/desktop/hyprland
					./modules/system/networking
					./modules/system/sound

					./modules/hosts/desktop

					{
						users.users.ethanthoma = {
							isNormalUser = true;
							extraGroups = [ "networkmanager" "wheel" ];
						};
						services.getty.autologinUser = "ethanthoma";
					}

					{
						environment.systemPackages = with pkgs; [
							llvmPackages.llvm
							llvmPackages.clang
                            rustc
                            cargo
						];
					}
				];
			};
		};

		homeConfigurations = {
			"ethanthoma" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;

                lib = nixpkgs.lib // home-manager.lib;

				modules = [
					./modules/users/ethanthoma
					./modules/apps/neovim
#					./modules/apps/steam

                    {
                        fonts.fontconfig.enable = true;
                        home.packages = [
                            (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
                        ];
                    }				
                ];
			};
		};
	};
}

