{ pkgs, ... }:

{
	home.packages = with pkgs; [
		eza
	];

	programs.bash = {
		bashrcExtra = ''
			alias ls='exa --icons -F -H --group-directories-first --git -1'
			alias ll='ls -alF'
			alias lt="exa --tree --level=2 --long --icons --git"
        '';
	};
}

