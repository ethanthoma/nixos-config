{ ... }:
{
  flake.homeManagerModules.neovim =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      mdformat =
        let
          pythonEnv = pkgs.python313.withPackages (ps: [
            ps.mdformat
            ps.mdformat-gfm
            ps.mdformat-footnote
            ps.mdformat-frontmatter
          ]);
        in
        pkgs.writeShellScriptBin "mdformat" ''
          exec ${pythonEnv}/bin/mdformat "$@"
        '';
    in
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;

        withNodeJs = true;
        withPython3 = true;
        withRuby = false;

        # nvim config is mutable (cloned repo owns init.lua); load HM's
        # generated provider setup via wrapper args instead of writing the file
        sideloadInitLua = true;
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
          mdformat
          pkgs.taplo
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
