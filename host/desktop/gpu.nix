{ config, pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-ocl
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
      rocmPackages.clr.icd
      clinfo
      amdvlk
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libva
      amdvlk
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot = {
    kernelParams = [
      "video=DP-1:2560x1440@60"
      "video=DP-2:2560x1440@60"
    ];
  };
}
