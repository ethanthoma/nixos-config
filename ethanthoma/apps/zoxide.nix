{ config, lib, pkgs, ... }:
let
  cfg = config.hm-zoxide;
in
{
  options.hm-zoxide.homeDirectory = lib.mkOption {
    type = lib.types.str;
    default = null;
  };

  config = lib.mkIf (cfg.homeDirectory != null) {
    home.packages = with pkgs; [
      zoxide
    ];

    programs.bash.bashrcExtra = ''
      export _ZO_DATA_DIR=${cfg.homeDirectory}/.config/zoxide
      export _ZO_RESOLVE_SYMLINKS=1
      eval "$(zoxide init bash --cmd cd)"
    '';
  };
}

