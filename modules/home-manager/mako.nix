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
          border-radius = "10";
          border-size = "2";
          background-color = palette.base;
          text-color = palette.text;
          border-color = palette.gold;
          progress-color = "over ${palette.surface}";
          default-timeout = "4000";
          "urgency=high" = {
            border-color = palette.love;
          };
        };
      };
    };
}
