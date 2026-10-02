{ pkgs, lib, ... }:

let
  username = "ethoma";
  home = "/home/${username}";
  records = "${home}/projects/typed-decisions-baseline/reports/jobs.jsonl";
  config_file = "/etc/pueue/pueue.yml";
  # Optional, mode 600, owned by the user: NOTIFY_WEBHOOK_URL=<Discord-style webhook>, the convention codex-web uses.
  notify_file = "/var/lib/pueue/notify.env";

  # Runs after every task: one JSON line with the outcome, exit code, duration, GPU resets seen in the kernel log
  # during the task, and counts of failure signatures in its output. A zero exit with signatures in the log is
  # recorded as finished-with-faults: "finished" is not "succeeded". Anything but a clean success is also posted to
  # the webhook in ${notify_file}, so a failure is known without a session open.
  callback = pkgs.writeShellScript "pueue-callback" ''
    set -u
    export PATH=${lib.makeBinPath [ pkgs.pueue pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.util-linux pkgs.curl ]}:/run/wrappers/bin
    id=$1
    task=$(pueue -c ${config_file} status --json | jq -c --arg id "$id" '.tasks[$id]')
    output=$(pueue -c ${config_file} log "$id" --full 2>/dev/null)
    faults=$(printf '%s' "$output" | grep -Eo 'MMU fault|Wait timeout|MemoryError|Traceback \(most recent call last\)|out of memory|device wedged' \
      | sort | uniq -c | awk '{count=$1; $1=""; sub(/^ /, ""); printf "%s\"%s\": %s", (NR > 1 ? ", " : ""), $0, count}')
    result=$(printf '%s' "$task" | jq -r '.status.Done.result | if type == "object" then keys[0] else . end')
    outcome=$result
    if [ "$result" = Success ] && [ -n "$faults" ]; then outcome=finished-with-faults; fi
    printf '%s' "$task" | jq -c --arg outcome "$outcome" --argjson faults "{$faults}" \
      --arg last "$(printf '%s' "$output" | tail -n 5 | tail -c 600)" \
      '{id: .id, label: .label, group: .group, outcome: $outcome, result: .status.Done.result,
        start: .status.Done.start, end: .status.Done.end, faults: $faults, command: .command, path: .path,
        last_output: $last}' >> ${records}
    if [ "$outcome" = Success ]; then exit 0; fi
    if [ ! -r ${notify_file} ]; then
      echo "task $id $outcome: no ${notify_file}, not notified" >&2
      exit 0
    fi
    . ${notify_file}
    label=$(printf '%s' "$task" | jq -r '.label // .command')
    jq -n --arg content "atlas job $id ($label): $outcome. $(printf '%s' "$output" | tail -n 3 | tail -c 400)" \
      '{content: $content}' \
      | curl --fail --silent --show-error --max-time 20 --header 'Content-Type: application/json' --data @- \
        "$NOTIFY_WEBHOOK_URL" >/dev/null \
      || echo "task $id $outcome: webhook post failed" >&2
  '';
in
{
  environment.systemPackages = [ pkgs.pueue ];

  # One config for the daemon and every client: `pueue` finds it through the symlink in the user's config directory.
  environment.etc."pueue/pueue.yml".text = ''
    client:
      restart_in_place: true
      read_local_logs: true
      show_confirmation_questions: false
      edit_mode: toml
      show_expanded_aliases: false
      dark_mode: false
      max_status_lines: null
      status_time_format: '%H:%M:%S'
      status_datetime_format: '%Y-%m-%d %H:%M:%S'
    daemon:
      # A failed GPU job pauses its group, so the next job does not run into the same fault unattended.
      pause_group_on_failure: true
      pause_all_on_failure: false
      compress_state_file: false
      callback: "${callback} {{id}}"
      env_vars: {}
      callback_log_lines: 10
      shell_command: null
    shared:
      pueue_directory: /var/lib/pueue
      runtime_directory: /run/pueue
      alias_file: null
      use_unix_socket: true
      unix_socket_path: /run/pueue/pueue.socket
      unix_socket_permissions: 448
      host: 127.0.0.1
      port: '6924'
      pid_path: null
      daemon_cert: null
      daemon_key: null
      shared_secret_path: null
    profiles: {}
  '';
  systemd.tmpfiles.rules = [
    "d ${home}/.config/pueue 0755 ${username} users -"
    "L+ ${home}/.config/pueue/pueue.yml - - - - ${config_file}"
  ];

  # The job queue for atlas: tasks are children of this daemon, so they outlive agent sessions (claude-shim's cgroup
  # is killed on restart) without a systemd unit per run. Group `gpu` runs one task at a time.
  systemd.services.pueued = {
    description = "Pueue task queue daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "mlflow.service" ];
    wants = [ "network-online.target" ];
    # A rebuild must never kill hours of training.
    restartIfChanged = false;
    path = [
      pkgs.bash pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.gnugrep pkgs.gnused pkgs.nix pkgs.procps pkgs.git
      pkgs.jq pkgs.pueue pkgs.util-linux
    ];
    environment = {
      HOME = home;
      NIX_PATH = "nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels";
    };
    serviceConfig = {
      User = username;
      Group = "users";
      StateDirectory = "pueue";
      RuntimeDirectory = "pueue";
      WorkingDirectory = home;
      ExecStart = "${pkgs.pueue}/bin/pueued -c ${config_file} -vv";
      ExecStartPost = pkgs.writeShellScript "pueue-groups" ''
        for attempt in 1 2 3 4 5 6 7 8 9 10; do
          ${pkgs.pueue}/bin/pueue -c ${config_file} status >/dev/null 2>&1 && break
          ${pkgs.coreutils}/bin/sleep 1
        done
        ${pkgs.pueue}/bin/pueue -c ${config_file} group add gpu --parallel 1 2>/dev/null || true
        ${pkgs.pueue}/bin/pueue -c ${config_file} parallel 1 --group gpu
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # logind otherwise deletes the user's POSIX semaphores and shared memory in /dev/shm when their last session
  # ends. Queued jobs outlive the login that started them: a Python worker pool then loses its semaphores mid-run
  # and every replacement worker dies at start-up (tinygrad's compile pool hung a training run this way).
  services.logind.settings.Login.RemoveIPC = false;
}
