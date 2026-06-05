{ ... }:
{
  flake.homeManagerModules.direnv =
    { pkgs, ... }:
    {
      programs = {
        direnv = {
          enable = true;
          enableBashIntegration = true;
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

        bash = {
          bashrcExtra = ''
            eval "$(direnv hook bash)"
          '';
        };
      };
    };
}
