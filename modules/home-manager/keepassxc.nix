{ ... }:
{
  flake.homeManagerModules.keepassxc =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      ini = "${config.xdg.configHome}/keepassxc/keepassxc.ini";
    in
    {
      home.packages = [ pkgs.keepassxc ];

      # programs.keepassxc.settings links the ini read-only and KeePassXC errors
      # on save, so force our keys via crudini. Tray keys keep the secret service
      # (it lives in the GUI process) alive when the window is closed.
      home.activation.keepassxcSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$(dirname "${ini}")"
        set_kp() { $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini --set "${ini}" "$1" "$2" "$3"; }
        set_kp FdoSecrets Enabled true
        set_kp FdoSecrets ConfirmAccessItem false
        set_kp FdoSecrets ConfirmDeleteItem false
        set_kp GUI ShowTrayIcon true
        set_kp GUI MinimizeToTray true
        set_kp GUI MinimizeOnClose true
        set_kp General OpenPreviousDatabasesOnStartup true
        set_kp General RememberLastDatabases true
        set_kp General MinimizeAfterUnlock true
      '';
    };
}
