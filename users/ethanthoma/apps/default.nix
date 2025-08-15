{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hm-apps;
in
{
  imports = [
    ./direnv.nix
    ./eza.nix
    ./fuzzel.nix
    ./fzf.nix
    ./ghostty.nix
    ./git.nix
    ./mako.nix
    ./neovim.nix
    ./starship.nix
    ./tmux.nix
    ./waybar.nix
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
    hm-neovim = {
      inherit username homeDirectory;
    };
    hm-tmux = {
      inherit username homeDirectory;
    };
    hm-zoxide.homeDirectory = homeDirectory;

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

      # recording
      pkgs.obs-studio
      pkgs.vlc

      # docs
      pkgs.mdformat
      pkgs.python313Packages.mdformat-tables
    ];

    programs.bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        mkdir -p ${homeDirectory}/.config

        # rip (rm improved)
        export GRAVEYARD=${homeDirectory}/.config/rip/graveyard

        alias rm='rip'
        alias cat='bat'
        alias find='fd'
      '';
    };
  };
}
