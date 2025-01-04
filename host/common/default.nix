{ pkgs, ... }:

{
  imports = [
    ./bluetooth.nix
    ./hyprland.nix
    ./ssh.nix
    ./sound.nix
  ];

  environment.systemPackages =
    let
      thorium = pkgs.callPackage ./thorium.nix { };
    in
    [
      thorium

      pkgs.ghostty
      pkgs.bottom
    ];
}
