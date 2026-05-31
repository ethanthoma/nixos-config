{ ... }:
{
  flake.homeManagerModules.keepassxc =
    { config, pkgs, lib, ... }:
    let
      ini = "${config.xdg.configHome}/keepassxc/keepassxc.ini";
    in
    {
      home.packages = [ pkgs.keepassxc ];

      # Turn on the freedesktop Secret Service in the *mutable* ini. HM's
      # programs.keepassxc.settings would link the whole file read-only and
      # KeePassXC would error on every save, so set just this key idempotently
      # on activation instead. The exposed group lives in the .kdbx and rides
      # along with the synced vault, so this flag is the only per-host step.
      home.activation.keepassxcFdoSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$(dirname "${ini}")"
        $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini --set "${ini}" FdoSecrets Enabled true
      '';
    };
}
