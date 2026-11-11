{ inputs, ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.workspace-indicator =
    { pkgs, lib, ... }:
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
      home.packages = [ package ];

      wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
        hl.layer_rule({ match = { namespace = "^workspace-indicator$" }, no_anim = true })
      '';

      systemd.user.services.workspace-indicator = {
        Unit = {
          Description = "Hyprland workspace indicator";
          PartOf = [ "hyprland-session.target" ];
          After = [ "hyprland-session.target" ];
          StartLimitIntervalSec = 30;
          StartLimitBurst = 5;
        };
        Service = {
          ExecStart = "${lib.getExe package} ${configuration}";
          Restart = "on-failure";
          RestartSec = 2;
          NoNewPrivileges = true;
          RestrictSUIDSGID = true;
          UMask = "0077";
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    };
}
