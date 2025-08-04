{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = builtins.map (filename: ./modules/${filename}) (
        builtins.attrNames (builtins.readDir ./modules)
      );

      flake.users = {
        "ethanthoma" = { };
      };

      flake.hosts = {
        "desktop" = {
          system = "x86_64-linux";
          users = [ "ethanthoma" ];
        };

        "surface" = {
          system = "x86_64-linux";
          users = [ "ethanthoma" ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.microsoft-surface-pro-9
          ];
        };
      };
    };
}
