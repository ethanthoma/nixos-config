{ config, lib, pkgs, ... }:

let
  cfg = config.hm-apps;
in
{
  imports = [
    ./direnv.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./neovim.nix
    ./starship.nix
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
    hm-neovim = { inherit username homeDirectory; };
    hm-tmux = { inherit username homeDirectory; };
    hm-zoxide.homeDirectory = homeDirectory;

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
      nix-index

      # recording
      obs-studio
      vlc
    ];

    programs.bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        mkdir -p ${homeDirectory}/.config

        # rip (rm improved)
        export GRAVEYARD=${homeDirectory}/.config/rip/graveyard

        alias cat='bat'
        alias find='fd'
      '';
    };
  };
}
