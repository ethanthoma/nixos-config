{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  codex_port = 46210;
  web_port = 8090;
  home = "/home/${username}";
  # Tracked flakes rather than nixpkgs, which lags upstream releases by weeks. Same sources as the surface.
  system = pkgs.stdenv.hostPlatform.system;
  codex = inputs.codex-cli.packages.${system}.default;
in
{
  imports = [ inputs.codex-web.nixosModules.coordination ];
  services.codex-web-coordination = {
    enable = true;
    port = 46213;
    gpuWatcher = {
      enable = true;
      user = username;
      repository = "${home}/projects/typed-decisions-baseline";
      configFile = "${home}/.config/typed-decisions/gpu-coordination.json";
    };
  };
  sops.templates."codex-web-tailnet.env".content = ''
    LISTEN_ADDRESS=${config.sops.placeholder.atlas_address}
    DESKTOP_CODEX_URL=ws://${config.sops.placeholder.desktop_address}:46210
    DESKTOP_PI_URL=http://${config.sops.placeholder.desktop_address}:46212
    WEB_HEALTH_URL=http://${config.sops.placeholder.atlas_address}:${toString web_port}/
  '';

  users.users.codex-web = {
    isSystemUser = true;
    group = "codex-web";
  };
  users.groups.codex-web = { };

  # Use the same Codex build for local logins and services.
  environment.systemPackages = [
    codex
  ];

  # The app-server refuses to start when CODEX_HOME is missing, which it is until the first `codex login`.
  systemd.tmpfiles.rules = [
    "d ${home}/.codex 0700 ${username} users -"
    "d ${home}/.codex/packages 0700 ${username} users -"
    "d ${home}/.codex/packages/app-server-daemon 0700 ${username} users -"
    "L+ ${home}/.codex/packages/app-server-daemon/current - - - - ${codex}/lib/codex"
  ];

  systemd.services.codex-web = {
    environment = {
      ATLAS_LOCAL_SERVICES = builtins.toJSON { "5000" = "http://100.105.130.102:5000"; };
      DESKTOP_LOCAL_SERVICES = builtins.toJSON { "8767" = "http://100.119.138.102:48767"; };
    };
    description = "Mobile web client for sessions on the desktop and atlas";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/var/lib/codex-web/server/bin/codex-web-server";
    restartIfChanged = false;
    path = [ pkgs.imagemagick ];
    serviceConfig = {
      ExecStart = "/var/lib/codex-web/server/bin/codex-web-server";
      WorkingDirectory = "/var/lib/codex-web";
      # Session history snapshots so the UI stays readable while a host is down.
      StateDirectory = "codex-web-cache";
      StateDirectoryMode = "0700";
      # Holds WEB_TOKEN and the <HOST>_<BACKEND>_TOKEN secrets.
      EnvironmentFile = [
        "/var/lib/codex-web.env"
        config.sops.templates."codex-web-tailnet.env".path
      ];
      Environment = [
        "PORT=${toString web_port}"
        "HISTORY_CACHE_DIRECTORY=/var/lib/codex-web-cache"
        "HOSTS=desktop:Desktop,atlas:Atlas"
        "DESKTOP_CODEX_PROJECTS_ROOT=/home/ethanthoma/projects"
        "ATLAS_CODEX_URL=ws://127.0.0.1:${toString codex_port}"
        "ATLAS_CODEX_PROJECTS_ROOT=${home}/projects"
        "ATLAS_PI_URL=http://127.0.0.1:46212"
        "ATLAS_PI_TOKEN_ENV=ATLAS_CLAUDE_TOKEN"
        "DESKTOP_PI_TOKEN_ENV=DESKTOP_CLAUDE_TOKEN"
      ];
      User = "codex-web";
      Group = "codex-web";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.services.codex-app-server = {
    description = "WebSocket access to the shared Codex daemon";
    path = [ pkgs.procps ];
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${inputs.codex-web.packages.${system}.server}/bin/codex-web-codex-proxy";
      EnvironmentFile = "/var/lib/codex-app-server.env";
      Environment = [
        "CODEX_HOME=${home}/.codex"
        "CODEX_BINARY=${codex}/bin/codex"
        "DISABLE_AUTOUPDATER=1"
        "LISTEN_ADDRESS=127.0.0.1"
        "PORT=${toString codex_port}"
      ];
      User = username;
      Group = "users";
      WorkingDirectory = home;
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = false;
      KillMode = "process";
      PrivateTmp = false;
      ProtectSystem = false;
    };
  };

  systemd.services.pi-shim = {
    description = "Pi sessions for codex-web on atlas";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment.PATH = lib.mkForce (
      lib.concatStringsSep ":" [
        "/run/wrappers/bin"
        "${home}/.nix-profile/bin"
        "${home}/.local/state/nix/profile/bin"
        "/etc/profiles/per-user/${username}/bin"
        "/nix/var/nix/profiles/default/bin"
        "/run/current-system/sw/bin"
      ]
    );
    serviceConfig = {
      ExecStart = lib.getExe inputs.codex-web.packages.${system}.pi-shim;
      EnvironmentFile = "/var/lib/claude-shim.env";
      Environment = [
        "LISTEN_ADDRESS=127.0.0.1"
        "PORT=46212"
        "TOKEN_ENV=CLAUDE_TOKEN"
        "PI_BIN=${inputs.pi.packages.${system}.default}/bin/pi"
        "PI_CODING_AGENT_DIR=${home}/.pi/agent"
        "PROJECTS_ROOT=${home}/projects"
      ];
      User = username;
      Group = "users";
      WorkingDirectory = home;
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      UMask = "0077";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ web_port ];
}
