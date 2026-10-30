{
  config,
  inputs,
  username,
  ...
}:
{
  imports = [ inputs.codex-web.nixosModules.team ];
  sops.secrets.relay-native-worker-token = {
    sopsFile = ../../../secrets/relay-worker-token.json;
    format = "binary";
    key = "";
    owner = username;
    mode = "0400";
  };
  services.relay-team = {
    enable = true;
    url = "http://atlas:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
  };
}
