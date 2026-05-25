{ ... }:
{
  flake.nixosModules.yubikey =
    { pkgs, ... }:
    {
      services.pcscd.enable = true;
      services.udev.packages = [ pkgs.yubikey-personalization ];

      environment.systemPackages = [ pkgs.yubikey-manager ];
    };
}
