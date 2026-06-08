{ ... }:
{
  flake.homeManagerModules.atuin =
    { ... }:
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
          theme.name = "rose-pine";
        };

        themes."rose-pine" = {
          theme.name = "rose-pine";
          colors = {
            AlertInfo = "#9ccfd8"; # foam
            AlertWarn = "#f6c177"; # gold
            AlertError = "#eb6f92"; # love
            Annotation = "#6e6a86"; # muted
            Base = "#e0def4"; # text
            Guidance = "#908caa"; # subtle
            Important = "#f6c177"; # gold
            Title = "#c4a7e7"; # iris
          };
        };
      };
    };
}
