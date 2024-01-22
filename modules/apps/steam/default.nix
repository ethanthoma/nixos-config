{ config, pkgs, ... }:

{
    config = {
        programs = {
            steam = {
                enable = true;
                remotePlay.openFirewall = true;
                dedicatedServer.openFirewall = true;
            };

            gamemode.enable = true;
        };


        hardware = {
            opengl = {
                enable = true;
                driSupport32Bit = true;
            };

            pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

            steam-hardware.enable = true;
        };

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

