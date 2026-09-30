{ ... }:
{
  flake.homeManagerModules.pi =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.pi-coding-agent ];

      home.sessionVariables = {
        PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi";
      };
    };
}
