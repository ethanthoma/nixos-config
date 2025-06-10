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
    inputs@{
      self,
      ...
    }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        { lib, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              nvidia.acceptLicense = true;
            };
          };
        };

      cfg.hosts =
        let
          username = "ethanthoma";
        in
        {
          "desktop" = {
            system = "x86_64-linux";
            inherit username;
          };

          "surface" = {
            system = "x86_64-linux";
            inherit username;
          };
        };

      imports =
        let
          modules = builtins.attrNames (builtins.readDir ./flake-parts);
        in
        builtins.map (filename: ./flake-parts/${filename}) modules;
    };
}
