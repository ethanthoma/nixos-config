{ home, pkgs, ... }:

{
	programs.neovim = {
		enable = true;
		defaultEditor = true;
		viAlias = true;
		vimAlias = true;

		withPython3 = true;
		extraPackages = with pkgs; [
			cargo
			clang
		];
	};

	home.sessionVariables.EDITOR = "nvim";
	programs.bash.sessionVariables.EDITOR = "nvim";
}
