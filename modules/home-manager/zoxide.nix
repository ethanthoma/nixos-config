{ ... }:
{
  flake.homeManagerModules.zoxide =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zoxide ];

      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
        options = [ "--cmd cd" ];
      };
    };
}
