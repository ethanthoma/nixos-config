{ inputs, self, ... }:

let
  system = "x86_64-linux";
  hostname = "surface";
  username = "ethanthoma";
in
{
  systems = [ system ];

  flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit hostname; };
    modules = [
      self.nixosModules.common
      self.nixosModules.bluetooth
      self.nixosModules.hyprland
      self.nixosModules.networking
      self.nixosModules.ssh
      self.nixosModules.sound
      self.nixosModules.hardware-surface
      self.nixosModules.power
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-hardware.nixosModules.microsoft-surface-pro-9
      {
        networking.hostName = hostname;
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ (final: prev: { thorium = prev.callPackage ../_packages/thorium.nix { }; }) ];

        users.users.${username} = {
          isNormalUser = true;
          extraGroups = [ "networkmanager" "wheel" "audio" ];
          home = "/home/${username}";
        };

        services.getty.autologinUser = username;

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username} = {
            imports = [ self.homeManagerModules.ethanthoma ];
            home.packages = [
              inputs.rose-pine-hyprcursor.packages.${system}.default
            ];
          };
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
            experimental-features = [ "nix-command" "flakes" ];
            trusted-users = [ "root" username ];
            max-jobs = "auto";
            cores = 0;
            keep-derivations = true;
            keep-outputs = true;
          };
          extraOptions = ''
            min-free = ${toString (1024 * 1024 * 1024)}
            max-free = ${toString (1024 * 1024 * 1024)}
          '';
        };
      }
    ];
  };
}
