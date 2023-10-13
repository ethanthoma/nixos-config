{ home, ... }:

{
	programs.neovim = {
		enable = true;
        defaultEditor = true;
		viAlias = true;
		vimAlias = true;
	};

	home.sessionVariables.EDITOR = "nvim";
    programs.bash.sessionVariables.EDITOR = "nvim";
}

