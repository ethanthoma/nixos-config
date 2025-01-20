{ pkgs, ... }:

{
  home.packages = [
    pkgs.git-lfs
  ];

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
}
