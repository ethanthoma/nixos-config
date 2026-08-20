{ ... }:
{
  flake.nixosModules.sigrok =
    { pkgs, ... }:
    {
      services.udev.packages = [ pkgs.libsigrok ];
      users.groups.plugdev = { };
    };
}
