{ ... }:

{
  imports = [
    ./docker.nix
    ./hardware.nix
    ./networking.nix
    ./steam.nix
    ./swap.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Vancouver";

  system.stateVersion = "23.05";
}
