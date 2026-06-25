{ ... }:
{
  flake.nixosModules.ccache =
    { config, ... }:
    {
      programs.ccache = {
        enable = true;
        packageNames = [ "linux" ];
      };

      nix.settings.extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
    };
}
