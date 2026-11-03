{ ... }:
{
  flake.nixosModules.power =
    { ... }:
    {
      powerManagement.enable = true;

      services.thermald.enable = true;

      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
        };
      };

      hardware.enableAllFirmware = true;

      services.system76-scheduler = {
        enable = true;
        useStockConfig = true;
      };

      services.logind = {
        settings = {
          Login = {
            HandleLidSwitch = "suspend-then-hibernate";
            HandleLidSwitchExternalPower = "suspend-then-hibernate";
            HandleLidSwitchDocked = "ignore";
            HandlePowerKey = "suspend-then-hibernate";
            HandleSuspendKey = "suspend";
            HandleHibernateKey = "hibernate";
            IdleAction = "suspend-then-hibernate";
            IdleActionSec = "30min";
            InhibitDelayMaxSec = "30s";
            UserStopDelaySec = "10s";
            KillUserProcesses = false;
          };
        };
      };

      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "2h";
        AllowSuspend = "yes";
        AllowHibernation = "yes";
        AllowSuspendThenHibernate = "yes";
        AllowHybridSleep = "yes";
        SuspendState = "mem";
        HibernateMode = "shutdown";
      };

      boot.resumeDevice = "/dev/disk/by-uuid/5f0d151e-2949-4ef3-af34-8d7cb0910d0b";
    };
}
