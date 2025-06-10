{
  lib,
  config,
  inputs,
  withSystem,
  ...
}:
let
  inherit (lib) mkOption recursiveUpdateUntil types;

  cfg = config.cfg;

  hostConfigType = types.submodule {
    options = {
      system = mkOption {
        type = types.str;
      };
      username = mkOption {
        type = types.str;
      };
    };
  };

  cfgType = types.submodule {
    options = {
      hosts = mkOption {
        type = types.attrsOf hostConfigType;
        default = { };
      };
    };
  };
in
{
  options = {
    cfg = mkOption {
      type = cfgType;
      default = { };
    };
  };

  config =
    let
      createHost =
        host: conf:
        withSystem conf.system (
          { pkgs, ... }:
          {
            nixosConfigurations.${host} = inputs.nixpkgs.lib.nixosSystem {
              inherit (conf) system;
              inherit pkgs;

              specialArgs = {
                inherit inputs;
                inherit (pkgs.stdenv) hostPlatform;
              };

              modules = [
                {
                  imports = [
                    ../host/common
                  ];

                  environment.systemPackages = [
                    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
                    pkgs.uutils-coreutils-noprefix
                  ];

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
                        conf.username
                      ];
                    };

                    extraOptions = ''
                      min-free = ${toString (1024 * 1024 * 1024)}
                      max-free = ${toString (1024 * 1024 * 1024)}
                    '';
                  };

                  users.users.${conf.username} = {
                    isNormalUser = true;
                    extraGroups = [
                      "networkmanager"
                      "wheel"
                      "audio"
                    ];
                  };
                  services.getty.autologinUser = conf.username;

                  networking.hostName = host;
                }

                ../host/${host}

                (if host == "surface" then inputs.nixos-hardware.nixosModules.microsoft-surface-pro-9 else { })
              ];
            };
          }
        );

      systemAttrset =
        let
          mergeSysConfig =
            a: b:
            recursiveUpdateUntil (
              path: _: _:
              (builtins.length path) > 2
            ) a b;

          sysConfigAttrsets = builtins.attrValues (builtins.mapAttrs createHost cfg.hosts);
        in
        builtins.foldl' mergeSysConfig { } sysConfigAttrsets;
    in
    {
      systems = lib.unique (builtins.attrValues (builtins.mapAttrs (_: v: v.system) cfg.hosts));

      flake = systemAttrset;
    };
}
