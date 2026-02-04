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
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
        binfmt.emulatedSystems = [ "aarch64-linux" ];

        initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "nvme"
          "usbhid"
          "usb_storage"
          "sd_mod"
          "iwlmvm"
          "iwlwifi"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];
        kernelPackages = pkgs.linuxPackages_6_12;
      };

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/77e43ca6-0814-4850-944f-b76d0687f79f";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/C711-E14B";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      fileSystems."/games" = {
        device = "/dev/disk/by-uuid/053b4e5a-9c96-4f2b-add1-cd5fb21b1676";
        fsType = "ext4";
        options = [
          "nofail"
          "noatime"
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
