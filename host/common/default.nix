{ pkgs, ... }:

{
  imports = [
    ./bluetooth.nix
    ./hyprland.nix
    ./networking.nix
    ./ssh.nix
    ./sound.nix
  ];

  environment.variables.QT_BEARER_POLL_TIMEOUT = "-1";

  environment.systemPackages =
    let
      thorium = pkgs.callPackage ./thorium.nix { };
    in
    [
      thorium

      pkgs.ghostty
      pkgs.bottom
      pkgs.openconnect_openssl
    ];
}
