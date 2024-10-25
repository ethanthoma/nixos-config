{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , home-manager
    , ...
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
          hosts = [ "desktop" "surface" ];

          base = {
            environment.systemPackages = [
              inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
            ];

            nix.settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              trusted-users = [
                "root"
                username
              ];
            };

            users.extraGroups.docker.members = [ "username-with-access-to-socket" ];

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
                ./host/${name}
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
          ];
        };
      };

    };
}
