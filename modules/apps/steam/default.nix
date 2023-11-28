{ config, pkgs, lib, ... }:

{
    config = {
        programs.steam = {
            enable = true;
            remotePlay.openFirewall = true;
            dedicatedServer.openFirewall = true;
        };

        hardware.opengl = { # this fixes the "glXChooseVisual failed" bug, context:
            enable = true;
            driSupport32Bit = true;
        };

        hardware.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

        hardware.steam-hardware.enable = true;

        programs.java.enable = true;

        environment.systemPackages = with pkgs; [ 
            steam 
            steam-run
            (steam.override {
                 extraPkgs = pkgs: [ bumblebee glxinfo ];
                 extraProfile = ''
                     export VK_ICD_FILENAMES=${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:${config.hardware.nvidia.package.lib32}/share/vulkan/icd.d/nvidia_icd32.json:$VK_ICD_FILENAMES
                 '';
             }).run
            vulkan-tools
        ];

        nixpkgs.overlays = [
            (final: prev: {
                 steam = prev.steam.override ({ extraPkgs ? pkgs': [], ... }: {
                     extraPkgs = pkgs': (extraPkgs pkgs') ++ (with pkgs'; [
                             libgdiplus
                     ]);
                 });
             })
        ];
    };
}

