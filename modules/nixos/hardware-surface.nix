{ ... }:
{
  flake.nixosModules.hardware-surface =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot = {
        loader = {
          systemd-boot = {
            enable = true;
            configurationLimit = 7;
          };
          efi.canTouchEfiVariables = true;
        };

        initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "nvme"
          "usb_storage"
          "sd_mod"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];

        kernelPatches = [
          {
            name = "disable-rust";
            patch = null;
            structuredExtraConfig = with lib.kernel; {
              RUST = lib.mkForce no;
            };
          }
        ];
      };

      hardware.microsoft-surface.kernelVersion = "stable";

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/0d010186-6d12-4657-91bc-2ca3bc42c904";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/A8E9-FDB3";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      swapDevices = [ { device = "/dev/nvme0n1p3"; } ];

      networking.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      time.timeZone = "America/Vancouver";

      system.stateVersion = "23.05";
    };
}
