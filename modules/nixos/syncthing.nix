{ ... }:
{
  flake.nixosModules.syncthing =
    { ... }:
    {
      services.syncthing = {
        enable = true;
        user = "ethanthoma";
        dataDir = "/home/ethanthoma";
        configDir = "/home/ethanthoma/.config/syncthing";
        openDefaultPorts = true;
      };
    };
}
