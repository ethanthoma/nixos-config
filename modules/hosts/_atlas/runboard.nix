{ inputs, username, ... }:

{
  imports = [ inputs.runboard.nixosModules.default ];

  services.runboard = {
    enable = true;
    roots = [ "/home/${username}/projects/typed-decisions-baseline" ];
    listen = "100.105.130.102:5000";
    user = username;
    pueueConfig = "/etc/pueue/pueue.yml";
    deploy.enable = true;
  };

  systemd.services.runboard.after = [ "tailscaled.service" ];
}
