{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      username = "ethanthoma";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.nvidia.acceptLicense = true;
      };

      inherit (nixpkgs) lib;
    in
    {
      nixosConfigurations = {
        desktop = lib.nixosSystem {
          inherit system pkgs;

          specialArgs = { inherit inputs; };

          modules = [
            ./host/desktop
            {
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
            }
            {
              nix.settings.trusted-users = [ "root" "ethanthoma" ];

              users.users.${username} = {
                isNormalUser = true;
                extraGroups = [ "networkmanager" "wheel" ];
              };
              services.getty.autologinUser = username;
            }
          ];
        };
        surface = lib.nixosSystem {
          inherit system pkgs;

          specialArgs = { inherit inputs; };

          modules = [
            ./host/surface
            {
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
            }
            {
              nix.settings.trusted-users = [ "root" "ethanthoma" ];

              users.users.${username} = {
                isNormalUser = true;
                extraGroups = [ "networkmanager" "wheel" ];
              };
              services.getty.autologinUser = username;
            }
          ];
        };
      };

      homeConfigurations = {
        ${username} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          lib = nixpkgs.lib // home-manager.lib;

          modules = [ ./${username} ];
        };
      };

    };
}
