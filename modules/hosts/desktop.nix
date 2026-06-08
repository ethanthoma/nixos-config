{ inputs, self, ... }:

let
  system = "x86_64-linux";
  hostname = "desktop";
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
      self.nixosModules.hardware-desktop
      self.nixosModules.impermanence
      self.nixosModules.gpu
      self.nixosModules.moonlander
      self.nixosModules.steam
      self.nixosModules.podman
      self.nixosModules.k3s
      self.nixosModules.yubikey
      self.nixosModules.yubikey-pam
      self.nixosModules.syncthing
      self.nixosModules.probe-rs
      inputs.home-manager.nixosModules.home-manager
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

        # Declarative password: hash lives at /persist/passwords/${username} (outside
        # this public repo), so it survives a future root wipe and never enters git.
        # `mutableUsers = false` means `passwd` is replaced by editing that file, and
        # root has no password (use `sudo -i`, not `su`).
        users.mutableUsers = false;

        users.users.${username} = {
          isNormalUser = true;
          extraGroups = [
            "networkmanager"
            "wheel"
            "audio"
            "video"
            "i2c"
            "plugdev"
          ];
          home = "/home/${username}";
          hashedPasswordFile = "/persist/passwords/${username}";
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
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            trusted-users = [
              "root"
              username
            ];
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
