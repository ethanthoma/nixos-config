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
    let
      logDir = "${config.xdg.stateHome}/atuin";
      databasePath = "${config.xdg.dataHome}/atuin/history.db";
      historyFile =
        if config.programs.bash.historyFile == null then
          "${config.home.homeDirectory}/.bash_history"
        else
          config.programs.bash.historyFile;
    in
    {
      programs.atuin = {
        enable = true;
        enableBashIntegration = true;

        flags = [ "--disable-up-arrow" ];

        forceOverwriteSettings = true;

        settings = {
          db_path = databasePath;
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
          auto_sync = false;
          theme.name = "hypersubatomic";

          logs = {
            search.file = "${logDir}/search.log";
            daemon.file = "${logDir}/daemon.log";
            ai.file = "${logDir}/ai.log";
          };
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

      home.sessionVariables = {
        ATUIN_HOME = "${config.xdg.dataHome}/atuin";
        ATUIN_CONFIG_DIR = "${config.xdg.configHome}/atuin";
      };

      home.activation.atuinImport = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        histfile="${historyFile}"
        db="${databasePath}"
        if [ ! -e "$db" ] && [ -s "$histfile" ]; then
          ATUIN_HOME="${config.xdg.dataHome}/atuin" \
            ATUIN_CONFIG_DIR="${config.xdg.configHome}/atuin" \
            ATUIN_DB_PATH="$db" HISTFILE="$histfile" \
            $DRY_RUN_CMD ${config.programs.atuin.package}/bin/atuin import bash
          $DRY_RUN_CMD ${pkgs.sqlite}/bin/sqlite3 "$db" "UPDATE history SET command = trim(command);"
        fi
      '';

      home.activation.atuinLogDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "${logDir}"
      '';
    };
}
