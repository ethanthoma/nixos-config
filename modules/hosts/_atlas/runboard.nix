{ ... }:

let
  project_directory = "/home/ethoma/projects/typed-decisions-baseline";
  program = "/home/ethoma/projects/runboard/result/bin/runboard";
  tailscale_address = "100.105.130.102";
  port = 5000;
in
{
  systemd.services.runboard = {
    description = "runboard: typed-decisions runs and scores";
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscaled.service" ];
    unitConfig.ConditionPathExists = program;
    serviceConfig = {
      ExecStart = "${program} --root ${project_directory} --listen ${tailscale_address}:${toString port} --state-dir /var/lib/runboard --nats-port 4223 --pueue /etc/pueue/pueue.yml";
      User = "ethoma";
      Group = "users";
      StateDirectory = "runboard";
      StateDirectoryMode = "0700";
      KillMode = "control-group";
      TimeoutStopSec = 15;
      # Covers the window after boot where tailscaled is up but the address is not yet assigned.
      Restart = "always";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
    };
  };
}
