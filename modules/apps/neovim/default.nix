{ ... }:

{
	programs.neovim = {
		enable = true;
		viAlias = true;
		vimAlias = true;
	};

	environment.variables.EDITOR = "neovim";
}

