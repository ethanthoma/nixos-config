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

            withPython3 = true;
            extraPackages = with pkgs; [
                cargo
                clang
                lua-language-server
            ];
        };

        home.sessionVariables.EDITOR = "nvim";
        programs.bash.sessionVariables.EDITOR = "nvim";

        home.activation = let
            args = {
                inherit pkgs lib;
                homeDirectory = cfg.homeDirectory;
            };
            mkMutableConfig = import ../mutable-config.nix args;
        in {
			nvim-config = mkMutableConfig {
				name = "nvim-config";
				repoUrl = "https://github.com/ethanthoma/neovim-config.git";
				configPath = ".config/nvim";
			};
        };
    };
}
