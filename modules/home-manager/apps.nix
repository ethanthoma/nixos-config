{ ... }:
{
  flake.homeManagerModules.apps =
    { config, pkgs, ... }:
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
        pkgs.unzip
        pkgs.fastfetch
        pkgs.nix-index
        pkgs.brightnessctl
        pkgs.jq
        pkgs.nil
        pkgs.dust
        pkgs.duf

        # recording
        pkgs.obs-studio
        pkgs.vlc

        # security
        pkgs.keepassxc

        # backup
        pkgs.rclone
      ];

      programs.bash = {
        enable = true;
        enableCompletion = true;
        bashrcExtra = ''
          mkdir -p ${config.home.homeDirectory}/.config

          # rip (rm improved)
          export GRAVEYARD=${config.home.homeDirectory}/.local/share/Trash

          alias rm='rip'
          alias cat='bat'
          alias find='fd'
          alias du='dust'
          alias df='duf'
        '';
      };
    };
}
