{ config, lib, pkgs, ... }:
let
    cfg = config.hm-neovim;
in {
    options.hm-neovim = with lib; {
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
        programs.neovim = {
            enable = true;
            defaultEditor = true;
            viAlias = true;
            vimAlias = true;

            withNodeJs = true;
            withPython3 = true;
            extraPackages = with pkgs; [
                cargo
                clang
                lua-language-server
                pkg-config 
                openssl
            ];
        };

        programs.bash = {
            bashrcExtra = ''
                export EDITOR="nvim"
                export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
            '';
        };

        home.activation = let
            args = {
                inherit pkgs lib;
                homeDirectory = cfg.homeDirectory;
            };
        mkMutableConfig = import ../utils/mutable-config.nix args;
        in {
            nvim-config = mkMutableConfig {
                name = "nvim-config";
                repoUrl = "git@github.com:ethanthoma/neovim-config.git";
                configPath = ".config/nvim";
            };
        };
    };
}
