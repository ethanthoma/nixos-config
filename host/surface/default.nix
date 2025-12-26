{ ... }:

{
  imports = [
    ./docker.nix
    ./hardware.nix
    ./power.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 7;
    };
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "America/Vancouver";

  system.stateVersion = "23.05";
}
