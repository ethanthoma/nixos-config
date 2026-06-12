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
      self.nixosModules.ccache
      self.nixosModules.power
      self.nixosModules.yubikey
      self.nixosModules.yubikey-pam
      self.nixosModules.syncthing
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-hardware.nixosModules.microsoft-surface-pro-9
      {
        networking.hostName = hostname;
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          (final: prev: {
            zen-browser = import ../_lib/zen-with-autoconfig.nix {
              inherit (prev) runCommand;
              zen = inputs.zen-browser.packages.${system}.default;
              fx-autoconfig = inputs.fx-autoconfig;
            };
          })
          inputs.claude-code.overlays.default
        ];

        users.users.${username} = {
          isNormalUser = true;
          extraGroups = [
            "networkmanager"
            "wheel"
            "audio"
          ];
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
      }
    ];
  };
}
