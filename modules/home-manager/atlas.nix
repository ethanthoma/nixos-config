{ ... }:
{
  flake.homeManagerModules.atlas =
    { pkgs, username, ... }:
    {
      home.username = username;
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "25.05";

      home.packages = [ pkgs.bottom ];

      programs.home-manager.enable = true;
      programs.bash.enable = true;

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        tmux.enableShellIntegration = true;
      };

      programs.neovim = {
        enable = true;
        viAlias = true;
      };

      programs.git = {
        enable = true;
        lfs.enable = true;
        package = pkgs.gitFull;
        userName = "Ethan Thoma";
        userEmail = "ethanthoma@gmail.com";
        aliases = {
          ci = "commit";
          co = "checkout";
          s = "status";
        };
        extraConfig = {
          push.autoSetupRemote = true;
          init.defaultBranch = "main";
          safe.directory = "/etc/nixos";
          commit.gpgsign = true;
          gpg.format = "ssh";
          user.signingkey = "~/.ssh/id_ed25519.pub";
        };
      };

      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
        options = [ "--cmd cd" ];
      };
    };
}
