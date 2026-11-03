{ inputs, ... }:
{
  flake.nixosModules.battery-trend =
    { pkgs, ... }:
    let
      battery-trend = inputs.battery-trend.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      environment.systemPackages = [ battery-trend ];
      systemd.user.services.battery-trend = {
        description = "Record battery and CPU activity trends";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = "${battery-trend}/bin/battery-trend record";
          Restart = "on-failure";
          RestartSec = 30;
        };
      };
    };
}
