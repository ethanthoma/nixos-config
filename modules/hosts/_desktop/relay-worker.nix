{ inputs, username }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  workers = map (slot: "relay-native-worker-${toString slot}") (
    lib.range 1 config.services.relay-native-worker.workersMax
  );
in
{
  imports = [ inputs.relay.nixosModules.native-worker ];
  sops.secrets.relay-native-worker-token = {
    sopsFile = ../../../secrets/relay-worker-token.json;
    format = "binary";
    key = "";
    owner = username;
    mode = "0400";
    restartUnits = map (worker: "${worker}.service") workers;
  };
  sops.secrets.relay-pi-token = {
    sopsFile = ../../../secrets/nix.yaml;
    owner = username;
    mode = "0400";
    restartUnits = [ "pi-shim.service" ];
  };
  sops.templates."relay-pi.env".content = "PI_TOKEN=${config.sops.placeholder.relay-pi-token}";
  services.relay-native-worker = {
    enable = true;
    user = username;
    name = "desktop.bodycam";
    url = "http://100.105.130.102:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
    directory = "/home/${username}/.local/share/relay-native-worker";
    workersMax = 4;
    packages = with pkgs; [
      bash
      fd
      git
      ripgrep
    ];
    profiles.bodycam-pi = [
      "${inputs.relay.packages.${system}.team}/bin/codex-web-team"
      "pi-task"
      "${inputs.pi.packages.${system}.default}/bin/pi"
      "morph/morph-dsv41flash"
      "low"
    ];
    profiles.bodycam-openpbr-worktree = [
      "${inputs.relay.packages.${system}.team}/bin/codex-web-team"
      "worktree-pi-task"
      "/home/${username}/projects/bevy_openpbr"
      "HEAD"
      "/home/${username}/.local/share/relay-worktrees/bodycam-openpbr"
      "${inputs.pi.packages.${system}.default}/bin/pi"
      "morph/morph-dsv41flash"
      "low"
    ];
    profiles.bodycam-openpbr-check = [
      "${inputs.relay.packages.${system}.team}/bin/codex-web-team"
      "worktree-pi-task-check"
      "/home/${username}/projects/bevy_openpbr"
      "HEAD"
      "/home/${username}/.local/share/relay-worktrees/bodycam-openpbr"
      "${inputs.pi.packages.${system}.default}/bin/pi"
      "morph/morph-dsv41flash"
      "low"
      "1800"
      "--"
      "${pkgs.coreutils}/bin/env"
      "CARGO_TARGET_DIR=target"
      "nix"
      "develop"
      "--command"
      "cargo"
      "test"
      "--workspace"
      "--all-targets"
      "--locked"
    ];
    sessionProfiles.bodycam = {
      project = "/home/${username}/projects/bodycam-lab";
      baselineStore = "/home/${username}/.local/share/relay/baselines";
      model = "deepseek-flash";
      effort = "low";
    };
  };
  systemd.services = lib.listToAttrs (
    map (worker: {
      name = worker;
      value.environment = {
        PI_CODING_AGENT_DIR = "/home/${username}/.config/pi";
        SHELL = "${pkgs.bash}/bin/bash";
      };
    }) workers
  );
  services.relay-team = {
    enable = true;
    url = "http://100.105.130.102:8090";
    tokenFile = config.sops.secrets.relay-native-worker-token.path;
  };
}
