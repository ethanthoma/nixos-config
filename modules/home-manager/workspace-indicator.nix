{ inputs, ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.workspace-indicator =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      package = inputs.workspace-indicator.packages.${pkgs.stdenv.hostPlatform.system}.default;
      configuration = pkgs.writeText "workspace-indicator.json" (
        builtins.toJSON {
          slots = 5;
          margin_top = 0;
          height = config.programs.waybar.settings.default.height;
          animation_ms = 320;
          background = palette.surface;
          active = palette.text;
          occupied = palette.subtle;
          empty = palette.muted;
          urgent = palette.love;
        }
      );
    in
    {
      wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
        hl.layer_rule({ match = { namespace = "^workspace-indicator$" }, no_anim = true })
      '';

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
