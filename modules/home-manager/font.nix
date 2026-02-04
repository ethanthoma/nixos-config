{ ... }:
{
  flake.homeManagerModules.font =
    { pkgs, ... }:
    {
      fonts.fontconfig.enable = true;

      home.packages = [
        pkgs.nerd-fonts.monaspace
      ];
    };
}
