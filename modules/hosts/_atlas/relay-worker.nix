{
  config,
  inputs,
  lib,
  username,
  ...
}:
let
  workers = map (slot: "relay-native-worker-${toString slot}") (
    lib.range 1 config.services.relay-native-worker.workersMax
  );
in
{
  imports = [
    inputs.codex-web.nixosModules.native-worker
    inputs.codex-web.nixosModules.team
  ];
  sops.secrets.relay-native-worker-token = {
    sopsFile = ../../../secrets/relay-worker-token.json;
    format = "binary";
    key = "";
    owner = username;
    mode = "0400";
    restartUnits = map (worker: "${worker}.service") workers;
  };
  sops.templates."relay-worker-url.env".content = ''
    CODEX_WEB_URL=http://${config.sops.placeholder.atlas_address}:8090
  '';
  services.relay-native-worker = {
    enable = true;
    user = username;
    name = "atlas.relay";
    url = "http://atlas:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
    workersMax = 4;
    sessionProfiles.relay = {
      project = "/home/${username}/projects/codex-web";
      model = "gpt-6.1-terra";
      effort = "low";
    };
  };
  services.relay-team = {
    enable = true;
    url = "http://atlas:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
  };
  systemd.services = lib.genAttrs workers (_: {
    serviceConfig.EnvironmentFile = config.sops.templates."relay-worker-url.env".path;
  });
}
