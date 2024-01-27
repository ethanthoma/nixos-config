{ pkgs, ... }:

{
	home.packages = with pkgs; [
		fzf
	];

	programs.bash = {
		bashrcExtra = ''
            if command -v fzf-share >/dev/null; then
                source "$(fzf-share)/key-bindings.bash"
                source "$(fzf-share)/completion.bash"
            fi
        '';
	};
}

