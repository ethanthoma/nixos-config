{ ... }:
{
  flake.nixosModules.syncthing =
    { ... }:
    let
      devices = {
        desktop.id = "EFCXJQQ-3ZJWG5G-WH6WZAI-3RVOQYW-GYMCZNQ-7I77GFA-LDICFI3-OTJ3HQZ";
        phone.id = "EB43N4A-JMHCQPD-HMRS5OR-S2NZSHD-6MZZBNR-O6TY6FX-ALIAYXB-NZIG7AS";
        surface.id = "HVCGH5U-5RMOF4S-W57CDCM-KZENKVO-F7IPPJW-HH5B7PA-6GQQZTK-LBDRMAV";
      };
    in
    {
      services.syncthing = {
        enable = true;
        user = "ethanthoma";
        dataDir = "/home/ethanthoma";
        configDir = "/home/ethanthoma/.config/syncthing";
        openDefaultPorts = true;

        settings = {
          inherit devices;
          folders."keepass" = {
            path = "/home/ethanthoma/keepass";
            devices = builtins.attrNames devices;
          };
        };
      };
    };
}
