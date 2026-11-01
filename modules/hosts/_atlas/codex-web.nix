{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  home = "/home/${username}";
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    inputs.relay.nixosModules.atlas
    inputs.relay.nixosModules.coordination
    inputs.relay.nixosModules.foundation-progress
  ];
  services.foundation-progress = {
    enable = true;
    controllerUser = username;
    bridgeExecutable = "/var/lib/codex-web/server/bin/foundation-bridge";
    mcpExecutable = "${home}/.local/state/relay-foundation/current/bin/relay-mcp";
    database = "${home}/.local/state/relay-foundation/relay/authority.sqlite";
  };
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
    DESKTOP_PI_URL=http://${config.sops.placeholder.desktop_address}:46212
  '';

  systemd.services.relay-runtime.serviceConfig.EnvironmentFile = lib.mkForce [
    "/var/lib/codex-web.env"
    "/var/lib/relay-pi.env"
    config.sops.templates."codex-web-tailnet.env".path
  ];
  systemd.services.relay-runtime.serviceConfig.Environment = lib.mkAfter [
    "ATLAS_PI_URL=http://127.0.0.1:46212"
    "ATLAS_AGENT_MEMORY_BINARY=${home}/.local/bin/agent-memory"
    "DESKTOP_AGENT_MEMORY_BINARY=/home/ethanthoma/.local/bin/agent-memory"
  ];

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
      ExecStart = lib.getExe inputs.relay.packages.${system}.pi-shim;
      EnvironmentFile = "/var/lib/relay-pi.env";
      Environment = [
        "LISTEN_ADDRESS=127.0.0.1"
        "PORT=46212"
        "TOKEN_ENV=PI_TOKEN"
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
}
