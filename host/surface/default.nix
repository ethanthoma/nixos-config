{ pkgs, ... }:

{
  networking.hostName = "desktop";

  imports = [
    ./hardware.nix
    ./swap.nix
    ./networking.nix
    ./hyprland.nix
    ./sound.nix
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    git
    tmux
    libnotify
    swww
    cliphist
    wl-clipboard
    bottom
    lxqt.pavucontrol-qt
    bluetuith
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  time.timeZone = "America/Vancouver";

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  system.stateVersion = "23.05";
}
