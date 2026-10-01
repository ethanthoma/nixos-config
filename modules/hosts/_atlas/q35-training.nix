{ pkgs, ... }:

let
  project_directory = "/home/ethoma/projects/typed-decisions-baseline";
in
{
  # Runs q35/synth/train_queue.sh so Qwen training survives crashes and reboots: the trainer checkpoints every
  # 100 steps and a restart resumes from there. Starts at boot until the queue writes its ALLDONE marker.
  systemd.services.q35-training = {
    description = "Typed-decisions Qwen training queue";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "mlflow.service"
    ];
    wants = [
      "network-online.target"
      "mlflow.service"
    ];
    # A rebuild must never kill hours of training; restart it by hand to pick up queue changes.
    restartIfChanged = false;
    unitConfig = {
      ConditionPathExists = [
        "${project_directory}/q35/synth/train_queue.sh"
        "!${project_directory}/reports/train_queue_ALLDONE"
      ];
      # A stage that fails on every attempt must not loop forever.
      StartLimitIntervalSec = "6h";
      StartLimitBurst = 3;
    };
    path = [
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.nix
      pkgs.procps
    ];
    environment.NIX_PATH = "nixpkgs=flake:nixpkgs";
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.bash}/bin/bash ${project_directory}/q35/synth/train_queue.sh";
      WorkingDirectory = project_directory;
      User = "ethoma";
      Group = "users";
      Restart = "on-failure";
      RestartSec = 60;
      # Stopping the unit kills the trainer too; the next start resumes from the last checkpoint.
      KillMode = "control-group";
      TimeoutStopSec = 30;
    };
  };
}
