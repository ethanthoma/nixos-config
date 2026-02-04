{ ... }:
{
  flake.homeManagerModules.neovim =
    { config, pkgs, lib, ... }:
    {
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
          cmake
          gcc
          python3
          gnumake
          nixfmt
          harper
        ];
      };

      programs.bash = {
        bashrcExtra = ''
          export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
        '';
      };

      home.activation =
        let
          args = {
            inherit pkgs lib;
            homeDirectory = config.home.homeDirectory;
          };
          mkMutableConfig = import ../_lib/mutable-config.nix args;
        in
        {
          nvim-config = mkMutableConfig {
            name = "nvim-config";
            repoUrl = "git@github.com:ethanthoma/neovim-config.git";
            configPath = ".config/nvim";
          };
        };
    };
}
