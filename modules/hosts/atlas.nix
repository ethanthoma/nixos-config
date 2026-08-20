{ inputs, self, ... }:

let
  system = "x86_64-linux";
  hostname = "atlas";
  username = "ethoma";
in
{
  systems = [ system ];

  flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit hostname username; };
    modules = [
      self.nixosModules.llama-server
      self.nixosModules.mcp-bridge
      self.nixosModules.open-historia
      self.nixosModules.minecraft-astral
      self.nixosModules.minecraft-terra
      self.nixosModules.tether
      self.nixosModules.cloudflared-atlas
      self.nixosModules.bmc-fan-fix
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      (
        {
          config,
          lib,
          pkgs,
          modulesPath,
          ...
        }:
        {
          imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

          boot = {
            loader.systemd-boot.enable = true;
            loader.efi.canTouchEfiVariables = true;

            initrd.availableKernelModules = [
              "xhci_pci"
              "ahci"
              "nvme"
              "usbhid"
              "usb_storage"
              "sd_mod"
            ];
            initrd.kernelModules = [ ];
            kernelModules = [ "kvm-amd" ];
            extraModulePackages = [ ];
          };

          fileSystems."/" = {
            device = "/dev/disk/by-uuid/e9b65a04-98c7-45b2-a3e5-277bdb00d339";
            fsType = "ext4";
          };

          fileSystems."/boot" = {
            device = "/dev/disk/by-uuid/EFEC-1695";
            fsType = "vfat";
            options = [
              "fmask=0077"
              "dmask=0077"
            ];
          };

          swapDevices = [ { device = "/dev/disk/by-uuid/89dc0de8-19a2-4e6a-abdb-2e055ad8e52c"; } ];

          networking.useDHCP = lib.mkDefault true;
          nixpkgs.hostPlatform = lib.mkDefault system;
          hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
          nixpkgs.config.allowUnfree = true;

          time.timeZone = "America/Vancouver";
          i18n.defaultLocale = "en_US.UTF-8";
          console.keyMap = "us";

          # sops: secrets are age-encrypted to this host's ssh key, so the
          # encrypted secrets/atlas.yaml is safe to keep in the repo.
          sops.defaultSopsFile = ../../secrets/atlas.yaml;
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

          security.sudo.wheelNeedsPassword = false;

          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "no";
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
            };
          };

          networking.firewall.allowedTCPPorts = [ 22 ];

          environment.systemPackages = [
            pkgs.git
            pkgs.neovim
            pkgs.tmux
            pkgs.fzf
            pkgs.lm_sensors
            pkgs.ipmitool
          ];

          system.stateVersion = "25.05";
        }
      )
      {
        networking.hostName = hostname;

        users.users = {
          root.hashedPassword = "!";
          ${username} = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHiAN7eu9G4A1OerVYGf+ixTU/gQJPtyRIBq5z/CRLex ethanthoma@gmail.com"
            ];
          };
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit username; };
          users.${username} = self.homeManagerModules.atlas;
        };
      }
    ];
  };
}
