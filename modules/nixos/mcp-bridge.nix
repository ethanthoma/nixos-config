{ ... }:
{
  flake.nixosModules.mcp-bridge =
    { pkgs, ... }:
    let
      mcp-bridge = pkgs.buildGoModule {
        pname = "atlas-mcp-bridge";
        version = "0.1.0";
        src = ../../pkgs/mcp-bridge;
        vendorHash = null;
      };
    in
    {
      networking.firewall.allowedTCPPorts = [ 8081 ];

      systemd.services.mcp-bridge = {
        description = "MCP HTTP bridge exposing the local LLM as a Claude Code 'delegate' tool";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "llama-server.service"
        ];
        serviceConfig = {
          ExecStart = "${mcp-bridge}/bin/atlas-mcp-bridge";
          EnvironmentFile = "/var/lib/llama-server.env";
          Environment = [
            "MCP_ADDR=0.0.0.0:8081"
            "LLAMA_URL=http://127.0.0.1:8080"
            "LLAMA_MODEL=local"
          ];
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
        };
      };
    };
}
