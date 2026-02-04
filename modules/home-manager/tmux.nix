{ ... }:
{
  flake.homeManagerModules.tmux =
    { config, pkgs, lib, ... }:
    {
      home.packages = with pkgs; [ tmux ];

      home.activation =
        let
          args = {
            inherit pkgs lib;
            homeDirectory = config.home.homeDirectory;
          };
          mkMutableConfig = import ../_lib/mutable-config.nix args;
        in
        {
          tmux-config = mkMutableConfig {
            name = "tmux-config";
            repoUrl = "https://github.com/ethanthoma/tmux-config.git";
            configPath = ".config/tmux";
            submodules = true;
          };
        };

      programs.bash = {
        bashrcExtra = ''
          # tmux autostart
          if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
              if tmux has-session &>/dev/null; then
                  tmux attach-session
              else
                  tmux new-session -s ${config.home.username}
              fi
          fi
        '';
      };
    };
}
