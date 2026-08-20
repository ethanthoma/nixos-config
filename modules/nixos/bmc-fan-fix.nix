{ ... }:
{
  flake.nixosModules.bmc-fan-fix =
    { pkgs, ... }:
    {
      boot.kernelModules = [
        "ipmi_devintf"
        "ipmi_si"
      ];

      systemd.services.bmc-fan-fix = {
        description = "pin FAN2/FAN3 at 50% duty so the BMC fan-fail boost never triggers";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ipmi() { for i in 1 2 3 4 5; do ${pkgs.ipmitool}/bin/ipmitool "$@" && return 0; sleep 5; done; return 1; }
          ipmi raw 0x3a 0xd0 0x11 0x0 0x2 0x2 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
          ipmi raw 0x3a 0xd0 0x0e 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32
          ipmi sensor thresh FAN2 lower 0 0 0
          ipmi sensor thresh FAN3 lower 0 0 0
        '';
      };
    };
}
