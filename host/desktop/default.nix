{ pkgs, ... }:

{
  networking.hostName = "desktop";

  imports = [
    ./docker.nix
    ./hardware.nix
    ./hyprland.nix
    ./gpu.nix
    ./sound.nix
    ./ssh.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    git
    kitty
    tmux
    mako
    libnotify
    swww
    fuzzel
    cliphist
    wl-clipboard
    bottom
    lxqt.pavucontrol-qt
    amdgpu_top
  ];

  services.fwupd.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  time.timeZone = "America/Vancouver";

  system.stateVersion = "23.05";
}
