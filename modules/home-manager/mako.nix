{ ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.mako =
    { ... }:
    {
      services.mako = {
        enable = true;
        settings = {
          anchor = "top-center";
          margin = "10";
          border-radius = "10";
          border-size = "2";
          background-color = palette.surface;
          text-color = palette.text;
          border-color = palette.overlay;
          progress-color = "over ${palette.gold}";
          default-timeout = "4000";
          max-visible = "5";
          group-by = "app-name";
          on-button-left = "dismiss";
          on-button-right = "dismiss-all";
          on-button-middle = "invoke-default-action";
          "urgency=high" = {
            border-color = palette.love;
            default-timeout = "0";
          };
          "app-name=yubikey-touch-detector" = {
            format = "<b>󰈷  %s</b>";
            font = "MonaspiceNe Nerd Font 11";
            border-color = palette.love;
            default-timeout = "0"; # persist until the key is tapped (detector closes it)
          };
        };
      };
    };
}
