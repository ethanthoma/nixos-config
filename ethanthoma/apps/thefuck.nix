{ pkgs, ... }:

{
	home.packages = with pkgs; [
		thefuck
	];

	programs.bash = {
		bashrcExtra = ''
			eval $(thefuck --alias)
			'';
	};
}
