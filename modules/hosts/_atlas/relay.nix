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
  foundation = inputs.relay-worker.packages.${system}.foundation;
  desktopAuthorities = pkgs.writeText "relay-foundation-authorities.json" (
    builtins.toJSON [
      {
        project = "project://9137bb3a-518c-440d-a63c-ab649e4a2551";
        source = "desktop/codex";
        url = "http://100.119.138.102:46214";
        token_file = "/run/credentials/relay-runtime.service/desktop-foundation-token";
      }
    ]
  );
in
{
  imports = [
    (import ../_shared/relay-morph.nix {
      credentialPath = "/var/lib/relay-volumes/authority/morph-auth.json";
    })
    inputs.relay.nixosModules.atlas
    inputs.relay.nixosModules.coordination
    inputs.relay-worker.nixosModules.foundation-progress
    inputs.relay-worker.nixosModules.host-controller
  ];
  services.relay-bounded-storage = {
    enable = true;
    resolverConfiguration = "nameserver 192.168.1.1\n";
  };
  systemd.tmpfiles.rules = [ "z /var/lib/relay-volumes/authority 0700 root root -" ];
  services.relay-fixed-controller = {
    enable = false;
    package = foundation;
    configFile = "/var/lib/relay-volumes/authority/controller-atlas-live-db7f2f0.json";
    tokenFile = "/run/secrets/relay-native-worker-token";
    natsUrl = "nats://127.0.0.1:46213";
    brokerService = "codex-web-nats";
  };
  services.relay-host-controller = {
    enable = true;
    package = foundation;
    stateDirectory = "/var/lib/relay-host";
    hostConfigurationFile = "${inputs.relay-worker}/host/atlas.cue";
    credentials = {
      morph = "/var/lib/relay-volumes/authority/morph-auth.json";
      relay-queue = "/var/lib/relay-host/queue-password";
    };
    checkProfiles = lib.genAttrs [ "affected" "integration" ] (_: {
      adapter = "cargo";
      policy = "/nix/store/hgkyl615b6ccbck7p8pjr6bwbrfsaxkh-relay-fixed-controller-policy.cue";
    });
    brokerService = "codex-web-nats";
    legacyBrokerCredentialFile = "/var/lib/relay-host/events-password";
    legacyBrokerStorageBytesMax = 268435456;
    writablePaths = [
      "/var/lib/relay-volumes"
      "/var/lib/relay-storage-sandbox"
    ];
    verificationUnits = map (name: "relay-storage-verify-${name}.service") [
      "worker-a"
      "worker-b"
      "check"
      "artifacts"
      "deps"
      "mirror"
      "authority"
      "logs"
    ];
    projects.relay = {
      controllerConfig = "/var/lib/relay-host/controller-template.json";
      authorityProject = "project://7101a33a-9b09-4bda-85d5-8b2f7da6668b";
      queueCredential = "relay-queue";
      resources = {
        worker = {
          cpu = 2;
          memory_bytes = 2147483648;
          storage_bytes = 17179869184;
        };
        check = {
          cpu = 4;
          memory_bytes = 4294967296;
          storage_bytes = 17179869184;
        };
      };
      limits = {
        cpu = 8;
        memory_bytes = 12884901888;
        tasks_max = 1024;
      };
    };
  };
  services.foundation-progress = {
    enable = true;
    authoritiesFile = toString desktopAuthorities;
    controllerUser = username;
    webUser = "codex-web";
    rootAuthority = true;
    storageAuthorityService = "relay-storage-verify-authority";
    storageMount = "/var/lib/relay-volumes/authority";
    bridgeExecutable = "/var/lib/codex-web-releases/current/server/bin/foundation-bridge";
    mcpExecutable = "${foundation}/bin/relay-mcp";
    coordinatorConfig = "/var/lib/relay-host/coordinator.json";
    database = "/var/lib/relay-volumes/authority/atlas-shared.sqlite";
  };
  systemd.services.relay-foundation-read = {
    requires = [ "relay-foundation-read.socket" ];
    after = [ "relay-foundation-read.socket" ];
    partOf = [ "relay-runtime.service" ];
    before = [ "relay-runtime.service" ];
    environment = {
      FOUNDATION_PEER_USERS = "${username},codex-web";
      FOUNDATION_ROOT_AUTHORITY = "1";
    };
  };
  systemd.services.relay-runtime.wants = [ "relay-foundation-read.service" ];
  services.relay-coordination = {
    enable = true;
    accountsFile = "/var/lib/relay-host/broker-accounts/current.json";
    port = 46213;
    gpuWatcher = {
      enable = true;
      user = username;
      repository = "${home}/projects/typed-decisions-baseline";
      configFile = "${home}/.config/typed-decisions/gpu-coordination.json";
    };
  };
  sops.secrets.relay-pi-token = {
    sopsFile = ../../../secrets/nix.yaml;
    restartUnits = [
      "pi-shim.service"
      "relay-runtime.service"
    ];
  };
  sops.templates."relay-pi.env".content = ''
    PI_TOKEN=${config.sops.placeholder.relay-pi-token}
    ATLAS_PI_TOKEN=${config.sops.placeholder.relay-pi-token}
    DESKTOP_PI_TOKEN=${config.sops.placeholder.relay-pi-token}
  '';
  sops.templates."relay-tailnet.env".content = ''
    DESKTOP_PI_URL=http://${config.sops.placeholder.desktop_address}:46212
  '';

  systemd.services.relay-runtime.serviceConfig.EnvironmentFile = lib.mkForce [
    "/var/lib/codex-web.env"
    config.sops.templates."relay-pi.env".path
    config.sops.templates."relay-tailnet.env".path
  ];
  systemd.services.relay-runtime.serviceConfig.LoadCredential = [
    "desktop-foundation-token:${config.sops.secrets.relay-pi-token.path}"
  ];
  systemd.services.relay-runtime.serviceConfig.Environment = lib.mkAfter [
    "ATLAS_PI_URL=http://127.0.0.1:46212"
    "ATLAS_AGENT_MEMORY_BINARY=${home}/.local/bin/agent-memory"
    "DESKTOP_AGENT_MEMORY_BINARY=/home/ethanthoma/.local/bin/agent-memory"
  ];

  systemd.services.pi-shim = {
    description = "Pi sessions for Relay on Atlas";
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
      EnvironmentFile = config.sops.templates."relay-pi.env".path;
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
