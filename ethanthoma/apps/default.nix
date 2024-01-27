{ config, lib, pkgs, ... }: 

let
    cfg = config.hm-apps;
in {
    imports = [
        ./direnv.nix
        ./eza.nix
        ./fzf.nix
        ./git.nix
        ./neovim.nix
        ./starship.nix
        ./thefuck.nix
        ./tmux.nix
        ./zoxide.nix
    ];

    options.hm-apps = with lib; {
        username = mkOption {
            type = types.str;
            default = null;
        };

        homeDirectory = mkOption {
            type = types.str;
            default = null;
        };
    };

    config = with cfg; {
        hm-zoxide.homeDirectory = homeDirectory;

        hm-tmux = {
            inherit username homeDirectory;   
        };

        home.packages = with pkgs; [
            gh
            tre
            wget
            zip
            entr
            rm-improved
            yq-go
            bat
            ripgrep
            trash-cli
            fd
            sd
            wl-clipboard
            unzip
            neofetch
        ];
    };
}
