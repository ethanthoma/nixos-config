{ pkgs, ... }:

{
  imports = [
    ./bluetooth.nix
    ./hyprland.nix
    ./networking.nix
    ./ssh.nix
    ./sound.nix
  ];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://hyprland.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

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
