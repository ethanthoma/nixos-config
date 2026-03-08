{ ... }:
{
  flake.homeManagerModules.claude =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.claude-code ];

      home.sessionVariables = {
        ENABLE_LSP_TOOL = "1";
      };
    };
}
