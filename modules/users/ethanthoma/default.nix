{ config, lib, pkgs, username, ... }:

let 
    username = "ethanthoma";
    homeDirectory = "/home/${username}";
in {
    home = let
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
            tre
            wget
            zip
            zoxide
            entr
            rm-improved

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
            # tmux autostart
            if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
                if tmux has-session &>/dev/null; then
                    tmux attach-session
                else
                    tmux new-session
                fi
            fi

            # zoxide
            export _ZO_DATA_DIR=${homeDirectory}/.config/zoxide
            export _ZO_RESOLVE_SYMLINKS=1

            eval "$(zoxide init bash --cmd cd)"

            # rip (rm improved)
            export GRAVEYARD=${homeDirectory}/.config/rip/graveyard
        '';
    };

    programs.home-manager.enable = true;
}

