{ ... }:
{
  flake.homeManagerModules.yubikey-touch-detector =
    { config, pkgs, ... }:
    {
      systemd.user.services.yubikey-touch-detector = {
        Unit = {
          Description = "Notify when the YubiKey is waiting for a touch";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          # --libnotify routes touch requests to the notification daemon (mako).
          # GNUPGHOME is relocated, so the GPG detector must be told where to watch.
          ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
          Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
          Restart = "on-failure";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
