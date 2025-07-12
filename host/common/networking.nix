{ pkgs, ... }:
{
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      unmanaged = [
        "wlan1"
      ];
      plugins = [
        pkgs.networkmanager-openconnect
      ];
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
