{ ... }:
{
  flake.nixosModules.common =
    { pkgs, ... }:
    {
      environment.variables.QT_BEARER_POLL_TIMEOUT = "-1";

      environment.systemPackages = [
        pkgs.zen-browser
        pkgs.bottom
        pkgs.openconnect_openssl
      ];
    };
}
