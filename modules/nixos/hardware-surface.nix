{ ... }:
{
  flake.nixosModules.hardware-surface =
    {
      config,
      lib,
      pkgs,
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
        kernelModules = [
          "kvm-intel"
          "pinctrl_tigerlake"
          "soc_button_array"
        ];
        extraModulePackages = [ ];
        blacklistedKernelModules = [ "surfacepro3_button" ];

        kernelPatches = [
          {
            name = "disable-rust";
            patch = null;
            structuredExtraConfig = {
              RUST = lib.mkForce lib.kernel.no;
            };
          }
        ];
      };

      hardware.microsoft-surface.kernelVersion = "stable";

      systemd.services.surface-buttons = {
        description = "Rebind soc_button_array for Surface volume buttons";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.kmod}/bin/modprobe -r soc_button_array || true
          ${pkgs.kmod}/bin/modprobe soc_button_array
        '';
      };

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
