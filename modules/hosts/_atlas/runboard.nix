{ ... }:

let
  project_directory = "/home/ethoma/projects/typed-decisions-baseline";
  program = "/home/ethoma/projects/runboard/result/bin/runboard";
  tailscale_address = "100.105.130.102";
  port = 5000;
in
{
  # runboard (gauge-numerics/runboard) renders typed-decisions' training logs and benchmark results as HTML, read
  # straight from the project's files. It listens on the Tailscale address only. The program is a `nix build` result
  # in the checkout: rebuild there and restart this unit to deploy a change.
  systemd.services.runboard = {
    description = "runboard: typed-decisions runs and scores";
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscaled.service" ];
    unitConfig.ConditionPathExists = program;
    serviceConfig = {
      ExecStart = "${program} --root ${project_directory} --listen ${tailscale_address}:${toString port}";
      User = "ethoma";
      Group = "users";
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
