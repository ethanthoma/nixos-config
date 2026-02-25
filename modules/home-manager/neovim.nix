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
        extraPackages = [
          pkgs.cargo
          pkgs.clang
          pkgs.lua-language-server
          pkgs.pkg-config
          pkgs.openssl
          pkgs.cmake
          pkgs.gcc
          pkgs.python3
          pkgs.gnumake
          pkgs.nixfmt
          pkgs.harper
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
