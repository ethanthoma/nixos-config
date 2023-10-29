{ config, lib, pkgs, username, ... }:

let 
    username = "ethanthoma";
    homeDirectory = "/home/${username}";
in {
    imports = [
        ./starship.nix
    ];

    home = let
        mkMutableConfig = import ./mutable-config.nix { inherit pkgs lib homeDirectory; };
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
            eza

            # rice
            neofetch
            grim
            slurp
            imagemagick

            # browser
            (callPackage ./thorium.nix { })
        ];

        activation = {
            nvim-config = mkMutableConfig {
                name = "nvim-config";
                repoUrl = "https://github.com/ethanthoma/neovim-config.git";
                configPath = ".config/nvim";
            };

            tmux-config = mkMutableConfig {
                name = "tmux-config";
                repoUrl = "https://github.com/ethanthoma/tmux-config.git";
                configPath = ".config/tmux";
                submodules = true;
            };
        };
    };

    gtk = {
        enable = true;
        theme = {
            name = "rose-pine";
            package = pkgs.rose-pine-gtk-theme;
        };
    };

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

            alias ls='exa --icons -F -H --group-directories-first --git -1'
            alias ll='ls -alF'
            alias lt="exa --tree --level=2 --long --icons --git"

            # launch starship prompt
            eval "$(starship init bash)"
        '';
    };

    programs.home-manager.enable = true;
}

