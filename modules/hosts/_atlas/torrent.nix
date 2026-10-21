{
  config,
  pkgs,
  lib,
  ...
}:
let
  profile = config.services.qbittorrent.profileDir;
  configuration = pkgs.writeText "qbittorrent.conf" ''
    [LegalNotice]
    Accepted=true

    [BitTorrent]
    Session\Interface=mullvad0
    Session\InterfaceName=mullvad0
    Session\DefaultSavePath=/data/torrents
    Session\TempPath=/data/torrents/incomplete
    Session\TempPathEnabled=true
    Session\Port=49160
    Session\LSDEnabled=false
    Session\MaxConnections=200
    Session\MaxConnectionsPerTorrent=50
    Session\QueueingSystemEnabled=true
    Session\MaxActiveDownloads=3
    Session\MaxActiveUploads=3
    Session\MaxActiveTorrents=5
    Session\GlobalMaxRatio=1
    Session\MaxRatioAction=0

    [Network]
    PortForwardingEnabled=false

    [Preferences]
    WebUI\Address=10.203.0.2
    WebUI\Port=8080
    WebUI\UseUPnP=false
    WebUI\LocalHostAuth=true
    WebUI\AuthSubnetWhitelist=10.203.0.1/32
    WebUI\AuthSubnetWhitelistEnabled=true
    WebUI\CSRFProtection=true
    WebUI\ClickjackingProtection=true
    WebUI\HostHeaderValidation=true
    WebUI\ServerDomains=atlas
  '';
in
{
  services.qbittorrent = {
    enable = true;
    extraArgs = [ "--confirm-legal-notice" ];
  };

  users.groups.torrents.members = [
    "ethoma"
    "qbittorrent"
  ];
  systemd.tmpfiles.rules = [
    "d /data/torrents 2770 qbittorrent torrents -"
    "d /data/torrents/incomplete 2770 qbittorrent torrents -"
  ];

  systemd.services.torrent-firewall = {
    description = "Restrict torrent traffic to the Mullvad interface";
    bindsTo = [ "mullvad-network.service" ];
    partOf = [ "mullvad-network.service" ];
    after = [ "mullvad-network.service" ];
    before = [ "qbittorrent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      NetworkNamespacePath = "/run/netns/mullvad";
      ExecStart = "${pkgs.nftables}/bin/nft --file ${pkgs.writeText "torrent-firewall.nft" ''
        destroy table inet torrent
        table inet torrent {
          chain output {
            type filter hook output priority -10; policy accept;
            meta skuid "qbittorrent" oifname "mullvad0" counter accept
            meta skuid "qbittorrent" oifname "mv-uplink" ip daddr 10.203.0.1 tcp sport 8080 ct state established counter accept
            meta skuid "qbittorrent" counter reject with icmpx type admin-prohibited
          }
        }
      ''}";
    };
  };

  systemd.services.qbittorrent = {
    requires = [ "torrent-firewall.service" ];
    bindsTo = [
      "mullvad-network.service"
      "torrent-firewall.service"
    ];
    partOf = [ "mullvad-network.service" ];
    after = [
      "torrent-firewall.service"
      "tailscaled-mullvad.service"
    ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/install -m 0600 ${configuration} ${profile}/qBittorrent/config/qBittorrent.conf";
      NetworkNamespacePath = "/run/netns/mullvad";
      BindReadOnlyPaths = [
        "${pkgs.writeText "torrent-resolv.conf" "nameserver 10.64.0.1\n"}:/etc/resolv.conf"
      ];
      SupplementaryGroups = [ "torrents" ];
      UMask = "0007";
      ProtectSystem = lib.mkForce "strict";
      ReadWritePaths = [
        profile
        "/data/torrents"
      ];
      MemoryMax = "2G";
      TasksMax = 128;
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = lib.mkForce 90;
    };
  };

  systemd.services.torrent-web = {
    description = "Forward the web interface into the torrent namespace";
    wantedBy = [ "multi-user.target" ];
    requires = [ "qbittorrent.service" ];
    partOf = [ "qbittorrent.service" ];
    after = [
      "qbittorrent.service"
      "tailscaled.service"
    ];
    serviceConfig = {
      EnvironmentFile = config.sops.templates."tailnet.env".path;
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8080,bind=\${ATLAS_ADDRESS},reuseaddr,fork,max-children=32 TCP:10.203.0.2:8080";
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      TasksMax = 64;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
