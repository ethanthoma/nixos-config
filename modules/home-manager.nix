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

  config.flake.homeConfigurations =
    let
      systems = lib.unique (lib.attrValues (mapAttrs (_: host: host.system) config.flake.hosts));

      systemConfigs = lib.genAttrs systems (
        system:
        withSystem system (
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
        )
      );
    in
    lib.foldl' (
      acc: system:
      acc
      // (lib.mapAttrs' (
        username: config: lib.nameValuePair "${username}@${system}" config
      ) systemConfigs.${system})
    ) { } systems;
}
