{ inputs, username }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  pi = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default;
  credential = "/run/relay-foundation/morph-auth.json";
  exporter = pkgs.stdenv.mkDerivation {
    pname = "relay-morph-credential";
    version = "1";
    src = ./relay-morph-credential.rs;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.rustc ];
    PI_EXECUTABLE = "${pi}/bin/pi";
    buildPhase = "rustc --edition=2021 -O $src -o relay-morph-credential";
    installPhase = "install -Dm755 relay-morph-credential $out/bin/relay-morph-credential";
  };
in
{
  config = lib.mkIf config.services.relay-host-controller.enable {
    systemd.tmpfiles.rules = [
      "d /run/relay-foundation 0700 root root -"
      "f ${credential} 0600 root root -"
    ];
    systemd.services.relay-morph-credential = {
      description = "Export the desktop user's Morph credential for Foundation";
      before = [
        "relay-project-bootstrap.service"
        "relay-host-prepare.service"
      ];
      environment.PI_CODING_AGENT_DIR = "/home/${username}/.config/pi";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = username;
        ExecStart = "${exporter}/bin/relay-morph-credential";
        StandardOutput = "truncate:${credential}";
        UMask = "0077";
        TimeoutStartSec = 30;
        KillMode = "control-group";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        MemoryMax = "512M";
        TasksMax = 64;
      };
    };
    systemd.services.relay-host-prepare = {
      requires = [ "relay-morph-credential.service" ];
      after = [ "relay-morph-credential.service" ];
    };
    systemd.services.relay-project-bootstrap = {
      requires = [ "relay-morph-credential.service" ];
      after = [ "relay-morph-credential.service" ];
    };
    services.relay-host-controller.credentials.morph = credential;
  };
}
