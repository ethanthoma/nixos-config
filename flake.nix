{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";

      username = "ethanthoma";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
      };

      inherit (nixpkgs) lib;
    in
    {
      nixosConfigurations =
        let
          hosts = [
            "desktop"
            "surface"
          ];

          base = {
            imports = [
              ./host/common
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
                  username
                ];
              };

              extraOptions = ''
                min-free = ${toString (1024 * 1024 * 1024)}
                max-free = ${toString (1024 * 1024 * 1024)}
              '';
            };

            users.users.${username} = {
              isNormalUser = true;
              extraGroups = [
                "networkmanager"
                "wheel"
                "audio"
              ];
            };
            services.getty.autologinUser = username;
          };

          createHost = name: {
            inherit name;

            value = lib.nixosSystem {
              inherit system pkgs;

              specialArgs = {
                inherit inputs;
              };

              modules = [
                base
                sops-nix.nixosModules.sops
                ./host/${name}
                ./sops.nix
                {
                  networking.hostName = name;
                }
                (if name == "surface" then nixos-hardware.nixosModules.microsoft-surface-pro-9 else { })
              ];
            };

          };
        in
        builtins.listToAttrs (builtins.map createHost hosts);

      homeConfigurations = {
        ${username} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          lib = nixpkgs.lib // home-manager.lib;

          modules = [
            ./${username}
            {
              home.packages = [
                inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
              ];

            }
            sops-nix.homeManagerModules.sops
          ];
        };
      };
    };
}
