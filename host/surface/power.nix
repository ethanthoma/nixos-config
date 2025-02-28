{ ... }:

{
  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
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
    lidSwitch = "suspend-then-hibernate";
    extraConfig = ''
      HandlePowerKey=suspend-then-hibernate
      IdleAction=suspend-then-hibernate
      IdleActionSec=30min
    '';
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=2h
  '';
}
