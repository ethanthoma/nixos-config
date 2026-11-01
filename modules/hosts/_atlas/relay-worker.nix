{
  config,
  inputs,
  username,
  ...
}:
{
  imports = [ inputs.relay.nixosModules.team ];
  sops.secrets.relay-native-worker-token = {
    sopsFile = ../../../secrets/relay-worker-token.json;
    format = "binary";
    key = "";
    owner = username;
    mode = "0400";
  };
  services.relay-team = {
    enable = true;
    url = "http://100.105.130.102:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
  };
}
