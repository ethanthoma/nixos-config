{ pkgs, lib, ... }:
{
  users.groups.holyfurries-runner = { };
  users.users.holyfurries-runner = {
    isSystemUser = true;
    group = "holyfurries-runner";
    home = "/var/lib/github-runner/holyfurries";
  };
  services.github-runners.holyfurries = {
    enable = true;
    name = "atlas-holyfurries";
    user = "holyfurries-runner";
    group = "holyfurries-runner";
    runnerGroup = "atlas-trusted";
    url = "https://github.com/holyfurries";
    tokenFile = "/var/lib/holyfurries-runner/registration-token";
    extraLabels = [
      "atlas"
      "holyfurries"
      "nixos"
    ];
    extraEnvironment.NIX_PATH = "nixpkgs=${pkgs.path}";
    extraEnvironment.DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
    extraPackages = with pkgs; [
      git
      nix
      bash
      coreutils
      curl
      cacert
      dotnet-sdk_8
      cargo
      rustc
      rustfmt
      clippy
    ];
    serviceOverrides = {
      ExecStart = lib.mkForce "${pkgs.github-runner}/lib/github-runner/Runner.Listener run --startuptype service";
      CPUQuota = "400%";
      MemoryHigh = "6G";
      MemoryMax = "8G";
      TasksMax = 512;
      Nice = 10;
      IOWeight = 25;
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
}
