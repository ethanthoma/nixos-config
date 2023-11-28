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
			overlays = []; config.nvidia.acceptLicense = true; };

		inherit (nixpkgs) lib;
	in {
		nixosConfigurations = {
            "laptop" = lib.nixosSystem {
                inherit system pkgs;

                specialArgs = { inherit inputs; };

                modules = [
					./modules/system/apps
					./modules/system/bluetooth
					./modules/system/boot/systemd
					./modules/system/desktop/hyprland
					./modules/system/networking
					./modules/system/sound
					./modules/system/gpu

                    ./modules/hosts/laptop
                ];
            };
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
					./modules/system/gpu

					./modules/hosts/desktop

					{
                        services.udev.extraRules = ''
                            # Rules for Oryx web flashing and live training
                            KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
                            KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

                            # Legacy rules for live training over webusb (Not needed for firmware v21+)
                            # Rule for all ZSA keyboards    
                            SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
                            # Rule for the Moonlander
                            SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
                            # Rule for the Ergodox EZ
                            SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
                            # Rule for the Planck EZ
                            SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"

                            # Wally Flashing rules for the Ergodox EZ
                            ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
                            ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
                            SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
                            KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

                            # Wally Flashing rules for the Moonlander and Planck EZ
                            SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11",     MODE:="0666",     SYMLINK+="stm32_dfu"
                        '';
                        users.groups.plugdev = {};

						users.users.ethanthoma = {
							isNormalUser = true;
							extraGroups = [ "networkmanager" "wheel" "plugdev" ];
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

                    {
                        nixpkgs.overlays = [
                            (self: super: {
                                 ollama = super.ollama.override {
                                     llama-cpp = super.llama-cpp.override { 
                                         cudaSupport = true;
                                         openblasSupport = false; 
                                         cudaVersion = "12";
                                     };
                                 };
                             })
                        ];
                        environment.systemPackages = with pkgs; [ ollama ];
                    }

                    (import ./modules/apps/steam)
				];
			};
		};

		homeConfigurations = {
			"ethanthoma" = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;

                lib = nixpkgs.lib // home-manager.lib;

				modules = [
					./modules/users/ethanthoma
                    ./modules/apps/direnv
					./modules/apps/neovim
					./modules/apps/starship
					./modules/apps/git

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

