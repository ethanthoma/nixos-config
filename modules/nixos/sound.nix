{ ... }:
{
  flake.nixosModules.sound =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lxqt.pavucontrol-qt
      ];

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };
}
