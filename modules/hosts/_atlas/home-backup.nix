{ pkgs, ... }:
{
  networking.firewall.allowedUDPPorts = [ 41643 ];

  systemd.services.tailscaled-home-backup = {
    description = "Manually selected Tailscale exit through home internet";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "notify";
      StateDirectory = "tailscale-home-backup";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "tailscale-home-backup";
      RuntimeDirectoryMode = "0700";
      BindReadOnlyPaths = [
        "${pkgs.writeText "home-backup-resolv.conf" "nameserver 1.1.1.1\nnameserver 9.9.9.9\n"}:/etc/resolv.conf"
      ];
      ExecStart = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale-home-backup/tailscaled.state --socket=/run/tailscale-home-backup/tailscaled.sock --tun=userspace-networking --port=41643";
      ExecStartPost = "${pkgs.tailscale}/bin/tailscale --socket=/run/tailscale-home-backup/tailscaled.sock set --hostname=atlas-home-backup --accept-dns=false --accept-routes=false --advertise-exit-node --exit-node=";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
