{ ... }:
{
  flake.homeManagerModules.git =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.git-lfs
      ];

      programs.git = {
        enable = true;
        lfs.enable = true;
        package = pkgs.gitFull;
        settings = {
          user = {
            name = "Ethan Thoma";
            email = "ethanthoma@gmail.com";
            signingkey = "~/.ssh/id_ed25519.pub";
          };
          alias = {
            ci = "commit";
            co = "checkout";
            s = "status";
          };
          push.autoSetupRemote = true;
          init.defaultBranch = "main";
          safe.directory = "/etc/nixos";
          commit.gpgsign = true;
          gpg.format = "ssh";
        };
      };
    };
}
