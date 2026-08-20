{ ... }:
{
  flake.nixosModules.open-historia =
    { pkgs, ... }:
    {
      users.users.open-historia = {
        isSystemUser = true;
        group = "open-historia";
      };
      users.groups.open-historia = { };

      networking.firewall.allowedTCPPorts = [ 3000 ];

      systemd.services.open-historia = {
        description = "Open Historia game server (node, port 3000)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        unitConfig.ConditionPathExists = "/var/lib/open-historia/server/server.js";
        serviceConfig = {
          ExecStart = "${pkgs.nodejs_22}/bin/node server/server.js";
          WorkingDirectory = "/var/lib/open-historia";
          EnvironmentFile = "/var/lib/open-historia.env";
          User = "open-historia";
          Group = "open-historia";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
