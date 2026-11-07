{ ... }:
{
  flake.homeManagerModules.agent-memory =
    { pkgs, ... }:
    let
      agent_memory = pkgs.callPackage ../_packages/agent-memory { };
    in
    {
      home.packages = [ agent_memory ];
      home.file.".local/bin/agent-memory" = {
        source = "${agent_memory}/bin/agent-memory";
        force = true;
      };
    };
}
