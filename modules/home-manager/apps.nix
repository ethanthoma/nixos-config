{ ... }:
{
  flake.homeManagerModules.apps =
    { config, pkgs, ... }:
    let
      mdformatWithPlugins =
        let
          pythonEnv = pkgs.python313.withPackages (ps: [
            ps.mdformat
            ps.mdformat-tables
            ps.mdformat-footnote
            ps.mdformat-frontmatter
          ]);
        in
        pkgs.writeShellScriptBin "mdformat" ''
          exec ${pythonEnv}/bin/mdformat "$@"
        '';
    in
    {
      home.packages = [
        pkgs.gh
        pkgs.tre
        pkgs.wget
        pkgs.zip
        pkgs.entr
        pkgs.rm-improved
        pkgs.yq-go
        pkgs.bat
        pkgs.ripgrep
        pkgs.trash-cli
        pkgs.fd
        pkgs.sd
        pkgs.wl-clipboard
        pkgs.unzip
        pkgs.neofetch
        pkgs.nix-index
        pkgs.brightnessctl
        pkgs.jq
        pkgs.nil
        pkgs.dust
        pkgs.duf

        # recording
        pkgs.obs-studio
        pkgs.vlc

        # docs
        mdformatWithPlugins
      ];

      programs.bash = {
        enable = true;
        enableCompletion = true;
        bashrcExtra = ''
          mkdir -p ${config.home.homeDirectory}/.config

          # rip (rm improved)
          export GRAVEYARD=${config.home.homeDirectory}/.config/rip/graveyard

          alias rm='rip'
          alias cat='bat'
          alias find='fd'
          alias du='dust'
          alias df='duf'
        '';
      };
    };
}
