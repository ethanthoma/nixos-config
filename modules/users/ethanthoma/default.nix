{ config, lib, pkgs, username, ... }:

{
    home = let
        username = "ethanthoma";
        homeDirectory = "/home/${username}";

        activationScripts = scripts: builtins.listToAttrs ( 
            map 
                ( { name, path, dependencies }: { 
                    name = name;
                    value = let
                        scriptText = '' ${ ( import path dependencies ).outPath }/bin/${ name } '';
                    in
                        lib.hm.dag.entryAfter [ "writeBoundary" ] scriptText;
                } ) 
                scripts
        );
    in {
        inherit username homeDirectory;

        stateVersion = "23.05";

        packages = with pkgs; [
            # CLI tools
            fzf
            gh
            tree
            wget
            zip

            # browser
            firefox-wayland

            # comm
            discord
        ];

        activation = activationScripts [
            {
                name = "tmux-config";
                path = ./tmux-config.nix;
                dependencies = { inherit pkgs homeDirectory; };
            }
            {
                name = "nvim-config";
                path = ./nvim-config.nix;
                dependencies = { inherit pkgs homeDirectory; };
            }
        ];
    };

    programs.home-manager.enable = true;
}

