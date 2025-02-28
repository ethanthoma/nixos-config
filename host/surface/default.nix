{ ... }:

{
  imports = [
    ./docker.nix
    ./hardware.nix
    ./networking.nix
    ./power.nix
    ./steam.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Vancouver";

  system.stateVersion = "23.05";
}
