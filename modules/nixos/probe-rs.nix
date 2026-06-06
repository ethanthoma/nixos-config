{ ... }:
{
  flake.nixosModules.probe-rs =
    { pkgs, ... }:
    {
      services.udev.packages = [ pkgs.probe-rs-tools ];
      users.groups.plugdev = { };
    };
}
