{ pkgs, lib, ... }:
{
  users.groups.matterstate-runner = { };
  users.users.matterstate-runner = {
    isSystemUser = true;
    group = "matterstate-runner";
    home = "/var/lib/github-runner/matterstate";
  };
  services.github-runners.matterstate = {
    enable = true;
    name = "atlas-matterstate";
    user = "matterstate-runner";
    group = "matterstate-runner";
    runnerGroup = "atlas-trusted";
    url = "https://github.com/matterstate";
    tokenFile = "/var/lib/matterstate-runner/registration-token";
    tokenType = "registration";
    extraLabels = [
      "atlas"
      "matterstate"
      "nixos"
    ];
    extraEnvironment.NIX_PATH = "nixpkgs=${pkgs.path}";
    extraEnvironment.DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
    extraEnvironment.NIX_CONFIG = ''
      max-jobs = 1
      cores = 2
    '';
    extraPackages = with pkgs; [
      git
      nix
      bash
      coreutils
      curl
      cacert
      dotnet-sdk_8
      jq
      gh
    ];
    serviceOverrides = {
      ExecStart = lib.mkForce "${pkgs.github-runner}/lib/github-runner/Runner.Listener run --startuptype service";
      CPUQuota = "200%";
      MemoryHigh = "4G";
      MemoryMax = "6G";
      TasksMax = 512;
      Nice = 10;
      IOWeight = 25;
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
}
