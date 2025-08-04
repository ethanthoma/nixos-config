{
  inputs,
  lib,
  config,
  flake-parts-lib,
  withSystem,
  ...
}:

let
  inherit (lib) mkOption types mapAttrs;
  inherit (flake-parts-lib) mkSubmoduleOptions;

  userConfigType = types.submodule {
    options = { };
  };
in

{
  options.flake = mkSubmoduleOptions {
    users = mkOption {
      type = types.attrsOf userConfigType;
      default = { };
      description = "User configurations";
    };
  };

  config.flake.homeConfigurations = withSystem "x86_64-linux" (
    { pkgs, ... }:
    mapAttrs (
      username: userConfig:
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        lib = inputs.nixpkgs.lib // inputs.home-manager.lib;

        modules = [
          ../users/${username}
          {
            home.packages = [
              inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
            ];
          }
        ];
      }
    ) config.flake.users
  );
}
