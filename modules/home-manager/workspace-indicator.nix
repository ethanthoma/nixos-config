{ inputs, ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.workspace-indicator =
    { pkgs, ... }:
    let
      package = inputs.workspace-indicator.packages.${pkgs.stdenv.hostPlatform.system}.default;
      configuration = pkgs.writeText "workspace-indicator.json" (
        builtins.toJSON {
          slots = 5;
          margin = 60;
          display_ms = 900;
          fade_ms = 200;
          background = palette.base;
          active = palette.iris;
          occupied = palette.text;
          empty = palette.muted;
        }
      );
    in
    {
      systemd.user.services.workspace-indicator = {
        Unit = {
          Description = "Hyprland workspace indicator";
          After = [ "hyprland-session.target" ];
          PartOf = [ "hyprland-session.target" ];
          StartLimitIntervalSec = 30;
          StartLimitBurst = 5;
        };
        Service = {
          ExecStart = "${package}/bin/workspace-indicator ${configuration}";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    };
}
