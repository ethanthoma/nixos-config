{ credentialPath }:
{ config, pkgs, ... }:
let
  directory = builtins.dirOf credentialPath;
in
{
  sops.secrets.relay-morph-auth = {
    sopsFile = ../../../secrets/relay-morph.yaml;
    key = "morph-auth";
    owner = "root";
    mode = "0400";
    restartUnits = [ "relay-morph-secret.service" ];
  };
  systemd.tmpfiles.rules = [ "d ${directory} 0700 root root -" ];
  systemd.services.relay-morph-secret = {
    description = "Install the sops-managed Foundation Morph credential";
    wantedBy = [ "multi-user.target" ];
    before = [ "relay-host-prepare.service" ];
    unitConfig.RequiresMountsFor = [ directory ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      UMask = "0077";
      ExecStart = "${pkgs.coreutils}/bin/install -m 0600 -- ${config.sops.secrets.relay-morph-auth.path} ${credentialPath}";
      TimeoutStartSec = 10;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ReadWritePaths = [ directory ];
    };
  };
  systemd.services.relay-host-prepare = {
    requires = [ "relay-morph-secret.service" ];
    after = [ "relay-morph-secret.service" ];
  };
}
