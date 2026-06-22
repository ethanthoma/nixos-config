{ ... }:
{
  flake.homeManagerModules.server-monitor =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      url = "https://llm.gaugenumerics.com/";
      state_dir = "${config.xdg.stateHome}/server-monitor";
      state_file = "${state_dir}/llm.json";
      last_file = "${state_dir}/last_status";

      probe = pkgs.writeShellApplication {
        name = "server-monitor-probe";
        runtimeInputs = [
          pkgs.curl
          pkgs.coreutils
          pkgs.libnotify
          pkgs.procps
        ];
        text = ''
          mkdir -p "${state_dir}"

          code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "${url}" || echo 000)

          if [ "$code" = "000" ] || { [ "$code" -ge 520 ] && [ "$code" -le 530 ]; }; then
            status=down
          else
            status=up
          fi

          prev=$(cat "${last_file}" 2>/dev/null || echo unknown)
          printf '%s' "$status" > "${last_file}"

          if [ "$status" = up ] && [ "$prev" = down ]; then
            notify-send -u critical "Server UP" "llm.gaugenumerics.com is back (HTTP $code)"
          fi

          if [ "$status" = up ]; then
            printf '{"text":"","class":"up","tooltip":"llm.gaugenumerics.com up (HTTP %s)"}\n' "$code" > "${state_file}"
          else
            printf '{"text":"","class":"down","tooltip":"llm.gaugenumerics.com DOWN (HTTP %s)"}\n' "$code" > "${state_file}"
          fi

          # Nudge waybar's custom/llm module to refresh immediately.
          pkill -RTMIN+8 waybar || true
        '';
      };
    in
    {
      systemd.user.services.server-monitor = {
        Unit = {
          Description = "Probe llm.gaugenumerics.com and notify when it recovers";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe probe;
        };
      };

      systemd.user.timers.server-monitor = {
        Unit.Description = "Run the llm.gaugenumerics.com probe every 5 minutes";
        Timer = {
          OnActiveSec = "15s";
          OnUnitActiveSec = "5min";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
