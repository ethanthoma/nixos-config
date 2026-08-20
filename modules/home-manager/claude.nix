{ inputs, ... }:
{
  flake.homeManagerModules.claude =
    { pkgs, ... }:
    {
      home.packages = [ inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      home.sessionVariables = {
        ENABLE_LSP_TOOL = "1";
      };
    };
}
