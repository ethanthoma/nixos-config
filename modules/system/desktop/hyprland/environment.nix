{ config, ... }:

{
	environment.sessionVariables = {
		WLR_NO_HARDWARE_CURSORS = "1";
		NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
	};
}

