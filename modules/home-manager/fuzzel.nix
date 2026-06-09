{ ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.fuzzel =
    { lib, ... }:
    let
      hex = lib.removePrefix "#";
    in
    {
      programs.fuzzel = {
        enable = true;
        settings = {
          border = {
            width = 2;
          };
          colors = {
            background = "${hex palette.base}dd";
            border = "${hex palette.gold}ff";
            match = "${hex palette.pine}ff";
            selection = "${hex palette.overlay}ff";
            selection-match = "${hex palette.pine}ff";
            selection-text = "${hex palette.text}ff";
            text = "${hex palette.text}ff";
          };
        };
      };
    };
}
