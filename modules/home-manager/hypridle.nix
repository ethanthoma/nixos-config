{ ... }:
{
  flake.homeManagerModules.hypridle =
    { lib, pkgs, ... }:
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
            after_sleep_cmd = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms on";
            ignore_dbus_inhibit = false;
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms off";
              on-resume = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms on";
            }
            {
              timeout = 1800;
              on-timeout = "systemctl suspend-then-hibernate";
            }
          ];
        };
      };
    };
}
