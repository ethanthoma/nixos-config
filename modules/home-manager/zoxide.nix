{ ... }:
{
  flake.homeManagerModules.zoxide =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      bakeInit = import ../_lib/bake-init.nix { inherit (pkgs) runCommand; };
    in
    {
      home.packages = [ pkgs.zoxide ];

      programs.zoxide = {
        enable = true;
        enableBashIntegration = false;
      };

      programs.bash.initExtra = lib.mkAfter ''
        [[ $- == *i* ]] && source ${bakeInit "zoxide" "${config.programs.zoxide.package}/bin/zoxide init bash --cmd cd"}
      '';
    };
}
