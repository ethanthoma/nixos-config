{ ... }:
{
  flake.homeManagerModules.claude =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.claude-code ];
    };
}
