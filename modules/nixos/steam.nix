{ ... }:
{
  flake.nixosModules.steam =
    { ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };

      services.udev.extraRules = ''
        SUBSYSTEM=="input", ATTRS{idVendor}=="1462", ATTRS{idProduct}=="7c56", ENV{ID_INPUT_JOYSTICK}="", ENV{ID_INPUT_ACCELEROMETER}=""
      '';
    };
}
