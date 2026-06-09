{ ... }:
{
  flake.homeManagerModules.direnv =
    { pkgs, config, ... }:
    let
      bakeInit = import ../_lib/bake-init.nix { inherit (pkgs) runCommand; };
    in
    {
      programs.direnv = {
        enable = true;
        enableBashIntegration = false;
        nix-direnv = {
          enable = true;
          package = pkgs.nix-direnv;
        };
        stdlib = ''
          use_gcloud() {
            export CLOUDSDK_CONFIG="''${1:-$PWD/.gcloud}"
            mkdir -p "$CLOUDSDK_CONFIG"
          }
        '';
      };

      programs.bash.initExtra = ''
        [[ $- == *i* ]] && source ${bakeInit "direnv" "${config.programs.direnv.package}/bin/direnv hook bash"}
      '';
    };
}
