{ pkgs, ... }:

{
	imports = [
		<nixos-wsl/modules>
	];

	wsl.enable = true;
	wsl.defaultUser = "ethanthoma";
	wsl.wslConf.network.hostname = "surface";

	networking.hostName = "surface";

    services.openssh.enable = true;

	nix.package = pkgs.nixFlakes;
	nix.extraOptions = ''
		experimental-features = nix-command flakes
	'';

    programs.dconf.enable = true;

	hardware.opengl.enable = true;

    virtualisation.docker.enable = true;
    users.extraGroups.docker.members = [ "ethanthoma" ];

	time.timeZone = "America/Vancouver";

    systemd.services.myservice = {
        enable = true;
        serviceConfig = {
            ExecStart = ''sh -c "ln -fs /mnt/wslg/runtime-dir/* /run/user/"%i'';
        };
    };

	system.stateVersion = "23.11";
}
