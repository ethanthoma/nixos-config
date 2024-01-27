{ ... }:

let 
	username = "ethanthoma";
	homeDirectory = "/home/${username}";
in {
	imports = [
        ./apps
		./rice
	];

    hm-apps = { 
        inherit username homeDirectory;
    };

	home = {
		inherit username homeDirectory;
		stateVersion = "23.05";
	};

	programs.home-manager.enable = true;
}
