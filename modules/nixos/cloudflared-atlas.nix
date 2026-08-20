{ ... }:
{
  # The tunnel UUID, ingress hostname, and credentials are host secrets that must
  # not enter this public repo, so cloudflared reads them from
  # /var/lib/cloudflared/config.yml (+ the credentials json it references),
  # provisioned out-of-band on the host. The service is a no-op until that file
  # exists.
  flake.nixosModules.cloudflared-atlas =
    { pkgs, ... }:
    {
      systemd.services.cloudflared-atlas = {
        description = "cloudflared tunnel (config in /var/lib/cloudflared/config.yml)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = "/var/lib/cloudflared/config.yml";
        serviceConfig = {
          ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config /var/lib/cloudflared/config.yml run";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
