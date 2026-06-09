{ ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.atuin =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      programs.atuin = {
        enable = true;
        enableBashIntegration = true;

        flags = [ "--disable-up-arrow" ];

        forceOverwriteSettings = true;

        settings = {
          search_mode = "fuzzy";
          filter_mode = "global";
          style = "compact";
          inline_height = 20;
          invert = true;
          show_preview = true;
          show_help = false;
          show_tabs = false;
          keys.scroll_exits = false;
          enter_accept = true;
          update_check = false;
          sync_address = "";
          theme.name = "hypersubatomic";
        };

        themes."hypersubatomic" = {
          theme.name = "hypersubatomic";
          colors = {
            AlertInfo = palette.foam;
            AlertWarn = palette.gold;
            AlertError = palette.love;
            Annotation = palette.muted;
            Base = palette.text;
            Guidance = palette.subtle;
            Important = palette.gold;
            Title = palette.iris;
          };
        };
      };

      home.activation.atuinImport = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        histfile="${config.programs.bash.historyFile}"
        db="${config.home.homeDirectory}/.local/share/atuin/history.db"
        if [ ! -e "$db" ] && [ -s "$histfile" ]; then
          HISTFILE="$histfile" $DRY_RUN_CMD ${config.programs.atuin.package}/bin/atuin import bash
          $DRY_RUN_CMD ${pkgs.sqlite}/bin/sqlite3 "$db" "UPDATE history SET command = trim(command);"
        fi
      '';
    };
}
