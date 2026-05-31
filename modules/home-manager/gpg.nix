{ ... }:
{
  flake.homeManagerModules.gpg =
    { config, pkgs, ... }:
    {
      programs.gpg = {
        enable = true;
        homedir = "${config.home.homeDirectory}/.local/share/gnupg";
      };

      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        pinentry.package = pkgs.pinentry-gnome3;
      };
    };
}
