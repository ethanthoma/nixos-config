{ inputs, username }:
{ config, lib, ... }:
let
  workers = map (slot: "relay-native-worker-${toString slot}") (
    lib.range 1 config.services.relay-native-worker.workersMax
  );
in
{
  imports = [ inputs.codex-web.nixosModules.native-worker ];
  sops.secrets.relay-native-worker-token = {
    sopsFile = ../../../secrets/relay-worker-token.json;
    format = "binary";
    key = "";
    owner = username;
    mode = "0400";
    restartUnits = map (worker: "${worker}.service") workers;
  };
  services.relay-native-worker = {
    enable = true;
    user = username;
    name = "desktop.bodycam";
    url = "http://atlas:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
    directory = "/home/${username}/.local/share/relay-native-worker";
    workersMax = 4;
    sessionProfiles.bodycam = {
      project = "/home/${username}/projects/bodycam-lab";
      baselineStore = "/home/${username}/.local/share/relay/baselines";
      model = "gpt-6.1-terra";
      effort = "low";
    };
  };
  services.relay-team = {
    enable = true;
    url = "http://atlas:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
  };
}
