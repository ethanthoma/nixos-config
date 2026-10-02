{ config, pkgs, ... }:

let
  # Expanded by systemd from the tailnet environment file (./tailnet.nix).
  mlflow_directory = "/home/ethoma/mlflow";
  tailscale_address = "\${ATLAS_ADDRESS}";
  port = 5000;
  allowed_hosts = [
    "localhost"
    "127.0.0.1"
    "atlas"
    "atlas.\${TAILNET_DOMAIN}"
    tailscale_address
  ];
  allowed_hosts_with_port = allowed_hosts ++ map (host: "${host}:${toString port}") allowed_hosts;
  allowed_origins = map (host: "http://${host}:${toString port}") allowed_hosts;
in
{
  # MLflow tracking server for typed-decisions, on localhost only: scoring scripts still log to 127.0.0.1:5000.
  # runboard has the same port on the Tailscale address and replaces it; this unit goes once nothing logs to it.
  systemd.services.mlflow = {
    description = "MLflow tracking server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    unitConfig.ConditionPathExists = "${mlflow_directory}/.venv/bin/mlflow";
    # The venv's wheels (numpy, pyarrow, ...) are prebuilt for FHS systems and need these on the loader path.
    environment.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.libdrm
    ];
    serviceConfig = {
      ExecStart = pkgs.lib.escapeShellArgs [
        "${mlflow_directory}/.venv/bin/mlflow"
        "server"
        "--backend-store-uri"
        "sqlite:///${mlflow_directory}/mlflow.db"
        "--artifacts-destination"
        "${mlflow_directory}/artifacts"
        "--serve-artifacts"
        "--host"
        "127.0.0.1"
        "--port"
        (toString port)
        "--workers"
        "2"
        "--cors-allowed-origins"
        (pkgs.lib.concatStringsSep "," allowed_origins)
        "--allowed-hosts"
        (pkgs.lib.concatStringsSep "," allowed_hosts_with_port)
      ];
      EnvironmentFile = config.sops.templates."tailnet.env".path;
      WorkingDirectory = mlflow_directory;
      User = "ethoma";
      Group = "users";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}
