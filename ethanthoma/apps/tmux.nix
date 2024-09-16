{ config, lib, pkgs, ... }:
let
    cfg = config.hm-tmux;
in {
    options.hm-tmux = with lib; {
        username = mkOption {
            type = types.str;
            default = null;
        };

        homeDirectory = mkOption {
            type = types.str;
            default = null;
        };
    };

    config = lib.mkIf (cfg.username != null && cfg.homeDirectory != null) {
        home.packages = with pkgs; [
            tmux
        ];

        home.activation = let
            args = {
                inherit pkgs lib;
                homeDirectory = cfg.homeDirectory;
            };
            mkMutableConfig = import ../utils/mutable-config.nix args;
        in {
            tmux-config = mkMutableConfig {
                name = "tmux-config";
                repoUrl = "https://github.com/ethanthoma/tmux-config.git";
                configPath = ".config/tmux";
                submodules = true;
            };
        };

        programs.bash = {
            bashrcExtra = ''
                # tmux autostart
                if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
                    if tmux has-session &>/dev/null; then
                        tmux attach-session
                    else
                        tmux new-session -s ${cfg.username}
                    fi
                fi
            '';
        };
    };
}

