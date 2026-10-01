{ ... }:
{
  services.tailscale.enable = true;
  imports = [
    ./mullvad-gateway.nix
    ./home-backup.nix
  ];
  services.tailscale.openFirewall = true;
  services.tailscale.useRoutingFeatures = "server";
  services.tailscale.extraSetFlags = [
    "--accept-dns=false"
    "--advertise-exit-node"
  ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
