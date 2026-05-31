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
        pkgs.trashy
        pkgs.yq-go
        pkgs.bat
        pkgs.ripgrep
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

          # trashy speaks the freedesktop trash spec, so `rm` and oil.nvim share
          # one ~/.local/share/Trash and `trash list`/`trash restore` see both.
          # trashy errors on rm-style flags, so drop them before handing it paths.
          rm() {
            local paths=()
            for arg in "$@"; do
              [[ $arg == -* ]] || paths+=("$arg")
            done
            trash put -- "''${paths[@]}"
          }

          alias cat='bat'
          alias find='fd'
          alias du='dust'
          alias df='duf'
        '';
      };
    };
}
