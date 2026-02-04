{ ... }:
{
  flake.nixosModules.power =
    { ... }:
    {
      powerManagement = {
        enable = true;
        powertop.enable = true;
      };

      services.thermald.enable = true;

      services.auto-cpufreq = {
        enable = true;
        settings = {
          battery = {
            governor = "powersave";
            turbo = "never";
          };
          charger = {
            governor = "performance";
            turbo = "auto";
          };
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

      systemd.sleep.extraConfig = ''
        HibernateDelaySec=2h
        AllowSuspend=yes
        AllowHibernation=yes
        AllowSuspendThenHibernate=yes
        AllowHybridSleep=yes
        SuspendState=mem
        HibernateState=disk
        HybridSleepState=disk
        HibernateMode=platform shutdown
        SuspendMode=
      '';

      boot.resumeDevice = "/dev/disk/by-uuid/5f0d151e-2949-4ef3-af34-8d7cb0910d0b";
    };
}
