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

            # rice
            neofetch
            grim
            slurp
            imagemagick
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

    gtk.enable = true;

    programs.bash = {
        enable = true;
        bashrcExtra = ''
            if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
                if tmux has-session &>/dev/null; then
                    tmux attach-session
                else
                    tmux new-session
                fi
            fi
        '';
    };

    programs.home-manager.enable = true;
}

