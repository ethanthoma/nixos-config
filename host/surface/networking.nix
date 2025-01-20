{ ... }:
{
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless = {
      iwd = {
        enable = true;
        settings = {
          IPv6 = {
            Enabled = true;
          };
          Settings = {
            AutoConnect = true;
          };
        };
      };
    };
  };
}
