{ pkgs, ... }:

{
  imports = [
    ./bluetooth.nix
    ./hyprland.nix
    ./sound.nix
  ];

  environment.systemPackages =
    let
      thorium = pkgs.callPackage ./thorium.nix { };
    in
    [
      thorium

      pkgs.kitty
      pkgs.bottom
    ];
}
