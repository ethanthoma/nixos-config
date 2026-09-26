{ ... }:
{
  flake.homeManagerModules.hypridle =
    { lib, pkgs, ... }:
    let
      # Long agent runs must not be cut short by the idle suspend. Holding a
      # logind idle inhibitor while any agent process exists makes hypridle skip
      # its inhibit-respecting listeners, and the lock is released as soon as the
      # last agent exits so the normal idle suspend applies again. Process names
      # are matched rather than wrapping the binaries so every launch path
      # (terminal, headless, spawned by another agent) is covered.
      agent_idle_inhibit = pkgs.writeShellApplication {
        name = "agent-idle-inhibit";
        runtimeInputs = [
          pkgs.procps
          pkgs.systemd
        ];
        text = ''
          # comm is truncated to 15 chars; the nix-wrapped claude shows up as ".claude-unwrapp".
          agent_pattern='^\.?(claude|codex)'
          poll_seconds=30

          while true; do
            if pgrep --uid "$UID" "$agent_pattern" > /dev/null; then
              # The inner loop runs under systemd-inhibit and gets its values as arguments, so single quotes are intended.
              # shellcheck disable=SC2016
              systemd-inhibit \
                --what=idle \
                --who=agent-idle-inhibit \
                --why="claude or codex is running" \
                --mode=block \
                bash -c 'while pgrep --uid "$UID" "$1" > /dev/null; do sleep "$2"; done' \
                _ "$agent_pattern" "$poll_seconds"
            fi
            sleep "$poll_seconds"
          done
        '';
      };
    in
    {
      # Safety net for the Surface's flaky lid switch: on some boots the lid
      # never delivers close events, so without an idle daemon the machine
      # stays fully awake (screen on, hot) inside the closed cover. logind's
      # IdleAction cannot cover this because nothing in a Hyprland session
      # sets the session IdleHint.
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            # Waking with the power button left the panel black: Hyprland still
            # believed the outputs were on (nothing turned them off before the
            # suspend), so dpms("on") after resume was a no-op and no frame was
            # ever re-committed. Turning the outputs off before sleep keeps
            # Hyprland's state honest, so the single "on" after resume does a
            # real re-enable with no off/on flash.
            before_sleep_cmd = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch 'hl.dsp.dpms(\"off\")'";
            after_sleep_cmd = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch 'hl.dsp.dpms(\"on\")'";
            ignore_dbus_inhibit = false;
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch 'hl.dsp.dpms(\"off\")'";
              on-resume = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch 'hl.dsp.dpms(\"on\")'";
              # Blank the panel even while an agent holds the idle inhibitor.
              ignore_inhibit = true;
            }
            {
              timeout = 1800;
              on-timeout = "systemctl suspend-then-hibernate";
            }
          ];
        };
      };

      systemd.user.services.agent-idle-inhibit = {
        Unit = {
          Description = "Block idle suspend while claude or codex is running";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = lib.getExe agent_idle_inhibit;
          Restart = "always";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
