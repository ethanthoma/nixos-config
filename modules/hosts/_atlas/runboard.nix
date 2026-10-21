{ inputs, ... }:

{
  imports = [ inputs.runboard.nixosModules.default ];

  services.runboard = {
    enable = true;
    roots = [ "/home/ethoma/projects/typed-decisions-baseline" ];
    listen = "100.105.130.102:5000";
    user = "ethoma";
    pueueConfig = "/etc/pueue/pueue.yml";
    deploy.enable = true;
  };

  systemd.services.runboard.after = [ "tailscaled.service" ];
}
