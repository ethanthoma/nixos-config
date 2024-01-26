{ ... }:

{
	programs.git = {
        enable = true;
        userName  = "Ethan Thoma";
        userEmail = "ethanthoma@gmail.com";
        aliases = {
            ci = "commit";
            co = "checkout";
            s = "status";
        };
        extraConfig = {
            push = { autoSetupRemote = true; };
            init = { defaultBranch = "main"; };
            safe = { directory = "/etc/nixos"; };
        };
	};
}

