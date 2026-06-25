{ inputs, ... }:
{
  flake.homeManagerModules.claude =
    { pkgs, ... }:
    {
      home.packages = [ inputs.claude-code.packages.${pkgs.system}.default ];

      home.sessionVariables = {
        ENABLE_LSP_TOOL = "1";
      };
    };
}
