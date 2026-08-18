{ ... }:
{
  flake.nixosModules.networking =
    { pkgs, ... }:
    {
      networking = {
        networkmanager = {
          enable = true;
          wifi.backend = "iwd";
          unmanaged = [
            "wlan1"
          ];
          plugins = [
            pkgs.networkmanager-openconnect
          ];
        };
        wireless = {
          iwd = {
            enable = true;
            settings = {
              IPv6 = {
                Enabled = true;
              };
              Settings = {
                AutoConnect = false;
              };
            };
          };
        };
      };

      # Local stub resolver so tailscaled cannot take over /etc/resolv.conf.
      # Without this, every DNS query is forwarded through tailscaled's stale
      # snapshot of the system resolvers, and a link flap (suspend/resume,
      # captive portal) kills all name resolution until tailscaled restarts.
      # With resolved, tailscaled only registers the tailnet domains via D-Bus
      # and regular queries go straight to the LAN resolver.
      services.resolved = {
        enable = true;
        fallbackDns = [
          "1.1.1.1"
          "9.9.9.9"
        ];
      };

      programs.nm-applet.enable = true;
    };
}
