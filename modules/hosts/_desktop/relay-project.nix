{
  inputs,
  username,
  repositorySource ? null,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  foundation = inputs.relay-worker.packages.${system}.foundation;
  server = inputs.relay.packages.${system}.server;
  pi = inputs.pi.packages.${system}.default;
  state = "/var/lib/relay-desktop";
  repository = "/home/${username}/projects/aigentrail";
  project = "project://9137bb3a-518c-440d-a63c-ab649e4a2551";
  base = "4e5afbf797aee9cf212dc16cfadba24a2a264581";
  source =
    if repositorySource != null then
      repositorySource
    else
      builtins.fetchGit {
        url = "file://${repository}";
        rev = base;
      };
  dependencies = pkgs.buildGoModule {
    pname = "gentrail-traces-dependencies";
    version = builtins.substring 0 12 base;
    src = source;
    modRoot = "modules/traces";
    vendorHash = "sha256-JIdDNQp33Yb4mbguHdqpboKQpL4TJ1drLigP1OvVVCQ=";
    env.CGO_ENABLED = "0";
    doCheck = false;
  };
  replacement = name: {
    module = "gentrail.ai/common/${name}";
    path = "services/common/${name}";
  };
  manifest = pkgs.writeText "gentrail-go-check.json" (
    builtins.toJSON {
      version = 1;
      source = ".";
      go = "${pkgs.go}/bin/go";
      git = "${pkgs.git}/bin/git";
      modules = [
        {
          path = "gentrail.ai/modules/traces";
          dir = "modules/traces";
          vendor = toString dependencies.goModules;
        }
      ];
      replacements = map replacement [
        "ruledsl"
        "capability"
        "eventstream"
      ];
      doc_policy = {
        mode = "allow";
        paths = [
          "docs"
          "README.md"
        ];
      };
      timeout_ms = 120000;
      budget_bytes = 1073741824;
      max_files = 100000;
      test_args = [ "./..." ];
      mode = "vendor";
    }
  );
  policy = pkgs.writeText "gentrail-check-policy.cue" ''
    policy: {
      checks: [{argv: ["${foundation}/bin/relay-go-check", "${manifest}", "{target_base}", "{candidate}"], timeout_seconds: 120}]
      retry: {repair_attempts_max: 1, delays_seconds: [2, 8], on: ["infrastructure", "timeout"], exhausted: "repair", check_failure: "repair"}
      target: {kind: "git", automatic: true, expected_revision_compare: true, receipt_reconciliation: true}
    }
  '';
  resolver = pkgs.writeText "relay-desktop-resolv.conf" "nameserver 192.168.1.1\n";
  mount = name: {
    path = "${config.services.relay-bounded-storage.mountDirectory}/${name}";
    uuid = config.services.relay-bounded-storage.volumes.${name}.uuid;
  };
  token = config.sops.secrets.relay-pi-token.path;
  broker_token = config.sops.templates."relay-foundation-broker".path;
  paths = with pkgs; [
    coreutils
    bash
    git
    ripgrep
    fd
    findutils
    gnused
    gnugrep
    gawk
    diffutils
    jq
  ];
  check_tools = foundation.checkEnvironment.tools;
  bootstrap = {
    version = 1;
    installation = "desktop-foundation";
    user = username;
    inherit repository base;
    origin = "https://github.com/aigentrail/aigentrail.git";
    branch = "main";
    state_directory = state;
    mirror = (mount "mirror").path;
    authority = "${(mount "authority").path}/gentrail.sqlite";
    host_cue = "${state}/host.cue";
    project_cue = "${state}/project.cue";
    controller = "${state}/controller.json";
    coordinator = "${state}/coordinator.json";
    runtime_template = "${state}/runtime-template.json";
    preparation = "${state}/preparation.json";
    executor_registry = "${state}/executors.json";
    capacity = {
      workers_max = 2;
      checks_max = 1;
      tasks_in_flight_max = 8;
      storage_max = "96GiB";
      memory_max = "16GiB";
      cpu_max = 8;
    };
    broker = {
      url = "nats://127.0.0.1:46213";
      credential = "desktop-broker";
      storage_max = "256MiB";
    };
    profile = {
      name = "flash";
      backend = "pi";
      provider = "morph";
      model = "morph-dsv41flash";
      effort = "low";
      credential = "morph";
    };
    project = {
      id = "gentrail";
      authority_project = project;
      queue_credential = "gentrail-queue";
      execution = {
        parallel_tasks_max = 2;
        worker_profile = "flash";
      };
      limits = {
        queued_tasks = 128;
        attempts_per_task = 2;
        task_timeout = "10m";
        storage = "64GiB";
        memory = "12GiB";
        cpu = 8;
        tokens_per_task = 100000;
      };
      checks = {
        adapter = "go";
        profile = "affected";
      };
      delivery = {
        remote = "origin";
        branch = "main";
      };
      resources = {
        worker = {
          cpu = 2;
          memory_bytes = 2147483648;
          storage_bytes = 17179869184;
          tasks_max = 256;
        };
        check = {
          cpu = 4;
          memory_bytes = 4294967296;
          storage_bytes = 17179869184;
          tasks_max = 256;
        };
      };
    };
    checks.affected = {
      adapter = "go";
      inherit policy;
    };
    credentials = {
      morph = "/run/relay-foundation/morph-auth.json";
      desktop-broker = broker_token;
      gentrail-queue = broker_token;
    };
    mounts = {
      log = mount "logs";
      mirror = mount "mirror";
      dependencies = mount "deps";
      artifacts = mount "artifacts";
      authority = mount "authority";
      slots = map (slot: {
        inherit (slot) role index uid;
        gid = slot.uid;
        mount = mount slot.volume;
      }) config.services.relay-bounded-storage.slots;
    };
    tools = {
      worker = "${foundation}/bin/relay-slot-codex-worker";
      check = "${foundation}/bin/relay-slot-check-worker";
      check_cargo = "${pkgs.cargo}/bin/cargo";
      inherit check_tools policy;
      codex = "${pi}/bin/pi";
      git = "${pkgs.git}/bin/git";
      resource_kernel = "${
        pkgs.callPackage "${inputs.relay-worker}/nix/resource-kernel-runtime.nix" { }
      }/bin/relay-resource-kernel";
      nix_store = "${pkgs.nix}/bin/nix-store";
      cue = "${pkgs.cue}/bin/cue";
      shell = "${pkgs.bash}/bin/bash";
      ca_certificate = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      inherit resolver;
      resolver_sha256 = builtins.hashString "sha256" "nameserver 192.168.1.1\n";
      tool_path = lib.makeBinPath paths;
      sandbox = "${pkgs.bubblewrap}/bin/bwrap";
      sandbox_root = "/var/lib/relay-storage-sandbox/root";
      credential_source = "/run/relay-foundation/morph-auth.json";
      ssh = "${pkgs.openssh}/bin/ssh";
      systemctl = "${pkgs.systemd}/bin/systemctl";
    };
  };
  broker = pkgs.writeText "relay-desktop-nats.conf" ''
    listen: "127.0.0.1:46213"
    max_payload: 32768
    include "/run/credentials/nats.service/project-accounts"
    jetstream { store_dir: "/var/lib/nats", max_memory_store: 64MB, max_file_store: 512MB }
  '';
in
{
  environment.persistence."/persist".directories = [
    {
      directory = state;
      mode = "0700";
    }
    {
      directory = config.services.relay-bounded-storage.backingDirectory;
      mode = "0700";
    }
    {
      directory = "/var/lib/nats";
      user = "nats";
      group = "nats";
      mode = "0700";
    }
  ];
  imports = [
    inputs.relay-worker.nixosModules.project-host
    inputs.relay.nixosModules.foundation-progress
    (import ../_shared/relay-morph.nix { credentialPath = "/run/relay-foundation/morph-auth.json"; })
  ];
  services.relay-project-host = {
    enable = true;
    package = foundation;
    declaration = bootstrap;
    brokerService = "nats";
    legacyBrokerCredentialFile = broker_token;
    resolverConfiguration = "nameserver 192.168.1.1\n";
  };
  services.nats = {
    enable = true;
    jetstream = true;
    port = 46213;
  };
  sops.templates."relay-foundation-broker".content = config.sops.placeholder.relay-pi-token;
  systemd.services.nats = {
    requires = [ "relay-host-prepare.service" ];
    after = [ "relay-host-prepare.service" ];
    serviceConfig = {
      ExecStart = lib.mkForce "${pkgs.nats-server}/bin/nats-server --config ${broker}";
      LoadCredential = [ "project-accounts:${state}/broker-accounts/current.json" ];
    };
  };
  services.foundation-progress = {
    enable = true;
    attachRuntime = false;
    socketGroup = "users";
    controllerUser = username;
    webUser = username;
    rootAuthority = true;
    storageAuthorityService = "relay-storage-verify-authority";
    storageMount = (mount "authority").path;
    database = "${(mount "authority").path}/gentrail.sqlite";
    coordinatorConfig = "${state}/coordinator.json";
    bridgeExecutable = "${server}/bin/foundation-bridge";
    mcpExecutable = "${foundation}/bin/relay-mcp";
    gatewayEnable = true;
    gatewayExecutable = "${server}/bin/foundation-gateway";
    gatewayPort = 46214;
    gatewayTokenFile = token;
    gatewayAllowedProject = project;
    gatewayAllowedSource = "desktop/codex";
  };
  services.relay-local.apps.foundation = {
    localPort = 46214;
    port = 46214;
  };
  systemd.services.relay-foundation-read = {
    requires = [ "relay-project-bootstrap.service" ];
    after = [ "relay-project-bootstrap.service" ];
  };
  systemd.services.relay-project-bootstrap = {
    unitConfig.RequiresMountsFor = [ state ];
    requires = [ "relay-morph-secret.service" ];
    after = [ "relay-morph-secret.service" ];
  };
  systemd.services.relay-storage-provision.unitConfig.RequiresMountsFor = [
    config.services.relay-bounded-storage.backingDirectory
  ];
}
