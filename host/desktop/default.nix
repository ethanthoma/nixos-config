{ pkgs, username, ... }:

{
	networking.hostName = "desktop";

	imports = [
		./hardware.nix
        ./hyprland.nix
        ./gpu.nix
        ./sound.nix
	];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    users.users.ethanthoma = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" "wheel" ];
    };
    services.getty.autologinUser = username;

	environment.systemPackages = with pkgs; 
    let
        thorium = callPackage ./thorium.nix { };
    in [
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
        pavucontrol
        thorium
	];

    networking.firewall.enable = false;

    hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
    };
    services.blueman.enable = true;

	time.timeZone = "America/Vancouver";

	system.stateVersion = "23.05";
}

