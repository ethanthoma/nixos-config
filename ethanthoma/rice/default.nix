{ home, pkgs, ... }:

{
	imports = [
		./font.nix
	];
    
	gtk = {
		enable = true;
		theme = {
			name = "rose-pine";
			package = pkgs.rose-pine-gtk-theme;
		};
	};
}
