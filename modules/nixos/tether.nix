{ inputs, ... }:
{
  flake.nixosModules.tether =
    { pkgs, ... }:
    let
      tether-bin = inputs.tether.packages.${pkgs.stdenv.hostPlatform.system}.default;
      tether = pkgs.writeShellScriptBin "tether" ''
        set -a
        [ -f /var/lib/tether.env ] && . /var/lib/tether.env
        set +a
        exec ${tether-bin}/bin/tether "$@"
      '';
      serviceDefaults = {
        Type = "oneshot";
        User = "ethoma";
        Group = "users";
      };
    in
    {
      environment.systemPackages = [ tether ];

      systemd.tmpfiles.rules = [ "d /var/lib/tether 0700 ethoma users -" ];

      systemd.services.tether-pulse = {
        description = "tether pulse: sync + triage + nudge";
        unitConfig.ConditionPathExists = "/var/lib/tether.env";
        serviceConfig = serviceDefaults // {
          ExecStart = "${tether}/bin/tether pulse";
        };
      };
      systemd.timers.tether-pulse = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/15";
          RandomizedDelaySec = 60;
        };
      };

      systemd.services.tether-digest = {
        description = "tether morning digest";
        unitConfig.ConditionPathExists = "/var/lib/tether.env";
        serviceConfig = serviceDefaults // {
          ExecStart = "${tether}/bin/tether digest";
        };
      };
      systemd.timers.tether-digest = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "07:00";
          Persistent = true;
        };
      };
    };
}
