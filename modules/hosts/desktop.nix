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
      self.nixosModules.tailscale
      self.nixosModules.ssh
      self.nixosModules.sound
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
            loader.systemd-boot = {
              enable = true;
              configurationLimit = 10;

              extraInstallCommands = ''
                if [ -e /dev/disk/by-uuid/C711-E14B ]; then
                  win=$(${pkgs.coreutils}/bin/mktemp -d)
                  ${pkgs.util-linux}/bin/mount -o ro /dev/disk/by-uuid/C711-E14B "$win"
                  ${pkgs.coreutils}/bin/mkdir -p /boot/EFI/Microsoft
                  ${pkgs.coreutils}/bin/cp -rT "$win/EFI/Microsoft" /boot/EFI/Microsoft
                  ${pkgs.util-linux}/bin/umount "$win"
                fi
              '';

              extraEntries."windows.conf" = ''
                title Windows
                efi /EFI/Microsoft/Boot/bootmgfw.efi
                sort-key zz-windows
              '';
            };
            loader.efi.canTouchEfiVariables = true;
            binfmt.emulatedSystems = [ "aarch64-linux" ];

            supportedFilesystems = [ "bcachefs" ];

            initrd.systemd.enable = true;
            initrd.luks.devices.cryptpool1 = {
              device = "/dev/disk/by-uuid/8856c898-8dbd-46d9-9001-616d11a3b601";
              crypttabExtraOpts = [ "fido2-device=auto" ];
              allowDiscards = true;
            };
            initrd.luks.devices.cryptpool2 = {
              device = "/dev/disk/by-uuid/0492d60a-cf05-473f-a514-3dcc06982cba";
              crypttabExtraOpts = [
                "tpm2-device=auto"
                "fido2-device=auto"
              ];
              allowDiscards = true;
            };

            initrd.systemd.storePaths = [ "${pkgs.bcachefs-tools}/bin/bcachefs" ];
            initrd.systemd.services.rollback = {
              description = "Wipe bcachefs root back to the blank snapshot";
              wantedBy = [ "initrd.target" ];
              after = [
                "systemd-cryptsetup@cryptpool1.service"
                "systemd-cryptsetup@cryptpool2.service"
                "unlock-bcachefs--.service"
                "unlock-bcachefs-nix.service"
                "unlock-bcachefs-persist.service"
              ];
              before = [ "sysroot.mount" ];
              unitConfig.DefaultDependencies = false;
              serviceConfig.Type = "oneshot";
              script = ''
                mkdir -p /tmp/rollback
                mount -t bcachefs /dev/mapper/cryptpool1:/dev/mapper/cryptpool2 /tmp/rollback
                if [ -e /tmp/rollback/root-blank ]; then
                  ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete /tmp/rollback/root
                  ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot /tmp/rollback/root-blank /tmp/rollback/root
                else
                  echo "rollback: root-blank missing, leaving root intact"
                fi
                umount /tmp/rollback
              '';
            };

            initrd.availableKernelModules = [
              "xhci_pci"
              "ahci"
              "nvme"
              "usbhid"
              "usb_storage"
              "sd_mod"
            ];
            initrd.kernelModules = [
              "usbhid"
              "hid_generic"
            ];
            kernelModules = [
              "kvm-amd"
              "i2c-dev"
              "ddcci_backlight"
              "iwlwifi"
            ];
            extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
            kernelPackages = pkgs.linuxPackages;
          };

          environment.systemPackages = [
            pkgs.bcachefs-tools
            pkgs.cryptsetup
          ];

          hardware.i2c.enable = true;
          services.udev.extraRules = ''
            SUBSYSTEM=="backlight", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
          '';

          fileSystems."/" = {
            device = "UUID=a10534f1-a973-413c-b771-4a62ec8ebc42";
            fsType = "bcachefs";
            options = [ "X-mount.subdir=root" ];
          };

          fileSystems."/nix" = {
            device = "UUID=a10534f1-a973-413c-b771-4a62ec8ebc42";
            fsType = "bcachefs";
            options = [ "X-mount.subdir=nix" ];
          };

          fileSystems."/home" = {
            device = "UUID=a10534f1-a973-413c-b771-4a62ec8ebc42";
            fsType = "bcachefs";
            options = [ "X-mount.subdir=home" ];
          };

          fileSystems."/persist" = {
            device = "UUID=a10534f1-a973-413c-b771-4a62ec8ebc42";
            fsType = "bcachefs";
            options = [ "X-mount.subdir=persist" ];
            neededForBoot = true;
          };

          fileSystems."/games" = {
            device = "UUID=a10534f1-a973-413c-b771-4a62ec8ebc42";
            fsType = "bcachefs";
            options = [ "X-mount.subdir=games" ];
          };

          systemd.tmpfiles.rules = [ "d /games 0755 ethanthoma users - -" ];

          fileSystems."/etc/nixos" = {
            device = "/persist/etc/nixos";
            fsType = "none";
            options = [ "bind" ];
          };

          fileSystems."/boot" = {
            device = "UUID=E682-0770";
            fsType = "vfat";
            options = [
              "fmask=0077"
              "dmask=0077"
            ];
          };

          swapDevices = [ ];

          networking.useDHCP = lib.mkDefault true;

          nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
          hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

          services.fwupd.enable = true;

          time.timeZone = "America/Vancouver";

          system.stateVersion = "23.05";
        }
      )
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
      }
    ];
  };
}
