{
  inputs,
  lib,
  config,
  flake-parts-lib,
  ...
}:

let
  inherit (lib) mkOption types mapAttrs;
  inherit (flake-parts-lib) mkSubmoduleOptions;

  hostConfigType = types.submodule {
    options = {
      system = mkOption {
        type = types.str;
        description = "System architecture for this host";
      };
      users = mkOption {
        type = types.listOf types.str;
        description = "Users to create on this system";
      };
      autoLogin = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "User to automatically login (defaults to single user if only one user)";
      };
      extraModules = mkOption {
        type = types.listOf types.deferredModule;
        default = [ ];
        description = "Additional NixOS modules for this host";
      };
    };
  };
in

{
  options.flake = mkSubmoduleOptions {
    hosts = mkOption {
      type = types.attrsOf hostConfigType;
      default = { };
      description = "Host configurations";
    };
  };

  config.flake.nixosConfigurations = mapAttrs (
    hostname: hostConfig:
    let

      autoLoginUser =
        if hostConfig.autoLogin != null then
          hostConfig.autoLogin
        else if builtins.length hostConfig.users == 1 then
          builtins.head hostConfig.users
        else
          null;

    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (hostConfig) system;

      specialArgs = { inherit hostname; };

      modules = [
        ../host/common
        ../host/${hostname}
        inputs.home-manager.nixosModules.home-manager

        {
          networking.hostName = hostname;

          nixpkgs.config.allowUnfree = true;

          users.users = lib.genAttrs hostConfig.users (username: {
            isNormalUser = true;
            extraGroups = [
              "networkmanager"
              "wheel"
              "audio"
            ];
            home = "/home/${username}";
          });

          services.getty.autologinUser = lib.mkIf (autoLoginUser != null) autoLoginUser;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users = lib.genAttrs hostConfig.users (username: {
              imports = [ ../users/${username} ];
              home.packages = [
                inputs.rose-pine-hyprcursor.packages.${hostConfig.system}.default
              ];
            });
          };

          nix = {
            gc = {
              automatic = true;
              dates = "daily";
              options = "--delete-older-than 7d";
            };

            optimise.automatic = true;

            settings = {
              auto-optimise-store = true;
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              trusted-users = [
                "root"
                autoLoginUser
              ];
            };

            extraOptions = ''
              min-free = ${toString (1024 * 1024 * 1024)}
              max-free = ${toString (1024 * 1024 * 1024)}
            '';
          };
        }
      ] ++ hostConfig.extraModules;
    }
  ) config.flake.hosts;
}
