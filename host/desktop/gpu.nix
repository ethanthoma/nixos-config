{ config, pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    powerManagement.finegrained = false;

    forceFullCompositionPipeline = true;

    open = false;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  boot = {
    kernelParams = [
      "video=DP-1:2560x1440@60"
      "video=DP-2:2560x1440@60"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];

    initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
  };
}
