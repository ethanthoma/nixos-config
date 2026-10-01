{
  pkgs,
  username,
  ...
}:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = [
    pkgs.bottom
  ];

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # One instruction file for Claude and Codex, shared with the surface.
  home.file.".claude/CLAUDE.md".source = ../../home-manager/AGENTS.md;
  home.file.".codex/AGENTS.md".source = ../../home-manager/AGENTS.md;

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
}
