{ config, pkgs, ... }:

{
	config.environment.systemPackages = with pkgs; [
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
	];
}

