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
        };

        bash = {
          bashrcExtra = ''
            eval "$(direnv hook bash)"
          '';
        };
      };
    };
}
