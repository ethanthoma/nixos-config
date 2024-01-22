{ config, lib, pkgs, ... }:
{

    # Enable OpenGL
    hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
            vaapiVdpau
            libvdpau-va-gl
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
        setLdLibraryPath = true;
    };

    environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
        modesetting.enable = true;

        powerManagement.enable = true;
        powerManagement.finegrained = false;

        open = false;

        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
    
    boot.kernelParams = [ 
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        "module_blacklist=amdgpu" 
    ];
}

