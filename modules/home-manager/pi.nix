{ inputs, ... }:
{
  flake.homeManagerModules.pi =
    { config, pkgs, ... }:
    {
      home.packages = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      home.sessionVariables = {
        PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi";
      };
    };
}
