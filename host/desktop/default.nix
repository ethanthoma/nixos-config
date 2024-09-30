{ pkgs, ... }:

{
  networking.hostName = "desktop";

  imports = [
    ./hardware.nix
    ./hyprland.nix
    ./gpu.nix
    ./sound.nix
    ./ssh.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages =
    with pkgs;
    let
      thorium = callPackage ./thorium.nix { };
    in
    [
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
      thorium
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
