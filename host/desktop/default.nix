{ pkgs, username, ... }:

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

  nix.settings.trusted-users = [ "root" "ethanthoma" ];

  users.users.ethanthoma = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "AAAAC3NzaC1lZDI1NTE5AAAAIMrmuBWb5KI1R0XN1b/R8uFxL9Bc2oILiU7xtJpBoOpz"
    ];
  };
  services.getty.autologinUser = username;

  environment.systemPackages = with pkgs;
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

