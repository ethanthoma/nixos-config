{ ... }:

{
  imports = [
    ./docker.nix
    ./hardware.nix
    ./gpu.nix
    ./moonlander.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  services.fwupd.enable = true;

  time.timeZone = "America/Vancouver";

  system.stateVersion = "23.05";
}
