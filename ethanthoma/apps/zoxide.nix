{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hm-zoxide;
in
{
  options.hm-zoxide.homeDirectory = lib.mkOption {
    type = lib.types.str;
    default = null;
  };

  config = lib.mkIf (cfg.homeDirectory != null) {
    home.packages = [ pkgs.zoxide ];

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      options = [ "--cmd cd" ];
    };
  };
}
