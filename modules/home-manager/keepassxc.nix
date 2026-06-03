{ ... }:
{
  flake.homeManagerModules.keepassxc =
    { config, pkgs, lib, ... }:
    let
      ini = "${config.xdg.configHome}/keepassxc/keepassxc.ini";
    in
    {
      home.packages = [ pkgs.keepassxc ];

      # KeePassXC is itself the freedesktop Secret Service provider (the daemon
      # lives in the GUI process, not keepassxc-cli), so to keep the keyring
      # available all session we run it backgrounded in the tray: open the last
      # DB at startup (one master-password + YubiKey unlock), hide to tray after
      # unlock, and minimize-on-close so closing the window never kills the
      # service. HM's programs.keepassxc.settings would link the whole *mutable*
      # ini read-only and KeePassXC would error on every save, so force just our
      # required keys idempotently on activation instead.
      home.activation.keepassxcSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$(dirname "${ini}")"
        set_kp() { $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini --set "${ini}" "$1" "$2" "$3"; }
        set_kp FdoSecrets Enabled true
        set_kp GUI ShowTrayIcon true
        set_kp GUI MinimizeToTray true
        set_kp GUI MinimizeOnClose true
        set_kp General OpenPreviousDatabasesOnStartup true
        set_kp General RememberLastDatabases true
        set_kp General MinimizeAfterUnlock true
      '';
    };
}
