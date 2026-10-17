{ config, pkgs, ... }:
{
  networking.firewall.extraCommands = ''
    for firewall in iptables ip6tables; do
      if ! "$firewall" -t mangle -C nixos-fw-rpfilter -i mv-host -j RETURN 2>/dev/null; then
        "$firewall" -t mangle -I nixos-fw-rpfilter 1 -i mv-host -j RETURN
      fi
    done
  '';
  networking.nat = {
    enable = true;
    externalInterface = "enp4s0f0np0";
    internalIPs = [ "10.203.0.0/30" ];
  };

  systemd.services.mullvad-network = {
    description = "Isolated network for the Mullvad gateway";
    before = [ "tailscaled-mullvad.service" ];
    path = [
      pkgs.iproute2
      pkgs.iptables
      pkgs.procps
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip netns add mullvad
      ip link add mv-host type veth peer name mv-uplink
      ip link set mv-uplink netns mullvad
      ip address add 10.203.0.1/30 dev mv-host
      ip -6 address add fd42:203::1/126 dev mv-host nodad
      ip link set mv-host up
      ip -n mullvad address add 10.203.0.2/30 dev mv-uplink
      ip -n mullvad -6 address add fd42:203::2/126 dev mv-uplink nodad
      ip -n mullvad link set lo up
      ip -n mullvad link set mv-uplink up
      ip -n mullvad route add default via 10.203.0.1
      ip netns exec mullvad sysctl -w net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1
      ip netns exec mullvad sysctl -w net.ipv4.conf.all.rp_filter=0 net.ipv4.conf.default.rp_filter=0
      for firewall in iptables ip6tables; do
        ip netns exec mullvad "$firewall" -P FORWARD DROP
        ip netns exec mullvad "$firewall" -A FORWARD -i mv-uplink -o mullvad0 -j ACCEPT
        ip netns exec mullvad "$firewall" -A FORWARD -i mullvad0 -o mv-uplink -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        ip netns exec mullvad "$firewall" -t nat -A POSTROUTING -o mullvad0 -j MASQUERADE
        ip netns exec mullvad "$firewall" -t mangle -A FORWARD -o mullvad0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
      done
    '';
    postStop = ''
      if ip link show mv-host >/dev/null 2>&1; then
        ip link delete mv-host
      fi
      if test -e /run/netns/mullvad; then
        ip netns delete mullvad
      fi
    '';
  };

  systemd.services.tailscaled-mullvad = {
    description = "Tailscale client for the upstream Mullvad connection";
    wantedBy = [ "multi-user.target" ];
    bindsTo = [ "mullvad-network.service" ];
    partOf = [ "mullvad-network.service" ];
    after = [
      "mullvad-network.service"
      "network-online.target"
      "firewall.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "notify";
      NetworkNamespacePath = "/run/netns/mullvad";
      StateDirectory = "tailscale-mullvad";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "tailscale-mullvad";
      RuntimeDirectoryMode = "0700";
      BindReadOnlyPaths = [
        "${pkgs.writeText "mullvad-resolv.conf" "nameserver 1.1.1.1\n"}:/etc/resolv.conf"
      ];
      ExecStart = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale-mullvad/tailscaled.state --socket=/run/tailscale-mullvad/tailscaled.sock --tun=mullvad0 --port=41642";
      ExecStartPost = "${pkgs.tailscale}/bin/tailscale --socket=/run/tailscale-mullvad/tailscaled.sock set --accept-dns=false --netfilter-mode=off --exit-node=\${EXIT_FIRST} --exit-node-allow-lan-access=true";
      EnvironmentFile = config.sops.templates."tailnet.env".path;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.services.mullvad-health = {
    description = "Recover the Mullvad gateway after repeated connection failures";
    after = [ "tailscaled-mullvad.service" ];
    requisite = [ "tailscaled-mullvad.service" ];
    path = [
      pkgs.curl
      pkgs.jq
      pkgs.tailscale
    ];
    serviceConfig = {
      Type = "oneshot";
      NetworkNamespacePath = "/run/netns/mullvad";
      BindReadOnlyPaths = [
        "${pkgs.writeText "mullvad-health-resolv.conf" "nameserver 10.64.0.1\n"}:/etc/resolv.conf"
      ];
      EnvironmentFile = config.sops.templates."tailnet.env".path;
      TimeoutStartSec = 60;
    };
    script = builtins.readFile ./mullvad-health.sh;
  };

  systemd.timers.mullvad-health = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitInactiveSec = "1min";
      AccuracySec = "5s";
    };
  };

  systemd.services.mullvad-routing = {
    description = "Route exit traffic through Mullvad with no direct fallback";
    wantedBy = [ "multi-user.target" ];
    requires = [ "mullvad-network.service" ];
    partOf = [ "mullvad-network.service" ];
    after = [ "mullvad-network.service" ];
    before = [ "tailscaled.service" ];
    path = [
      pkgs.iproute2
      pkgs.gnugrep
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for family in -4 -6; do
        ip "$family" route replace blackhole default table 100 metric 32767
        if ! ip "$family" rule show priority 5300 | grep -q .; then
          ip "$family" rule add priority 5300 iif tailscale0 lookup 100
        fi
        if ! ip "$family" rule show priority 5301 | grep -q .; then
          ip "$family" rule add priority 5301 iif tailscale0 prohibit
        fi
      done
      ip route replace default via 10.203.0.2 dev mv-host table 100 metric 10
      ip -6 route replace default via fd42:203::2 dev mv-host table 100 metric 10
      if ! ip rule show priority 5302 | grep -q .; then
        ip rule add priority 5302 to 10.64.0.1/32 lookup 100
      fi
    '';
  };

  systemd.services.tailscaled = {
    requires = [ "mullvad-routing.service" ];
    after = [ "mullvad-routing.service" ];
    serviceConfig.BindReadOnlyPaths = [
      "${pkgs.writeText "exit-node-resolv.conf" "nameserver 10.64.0.1\n"}:/etc/resolv.conf"
    ];
  };
}
