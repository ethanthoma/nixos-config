{ ... }:
{
  flake.nixosModules.hardware-desktop =
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
        };
        loader.efi.canTouchEfiVariables = true;
        binfmt.emulatedSystems = [ "aarch64-linux" ];

        # bcachefs needs a recent kernel (out-of-tree module is broken on 6.12)
        supportedFilesystems = [ "bcachefs" ];

        initrd.systemd.enable = true;
        initrd.luks.devices.cryptpool1 = {
          device = "/dev/disk/by-uuid/8856c898-8dbd-46d9-9001-616d11a3b601";
          crypttabExtraOpts = [ "fido2-device=auto" ];
          allowDiscards = true;
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
    };
}
