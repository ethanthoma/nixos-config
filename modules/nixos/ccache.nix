{ ... }:
{
  flake.nixosModules.ccache =
    { config, ... }:
    {
      programs.ccache = {
        enable = true;
        packageNames = [ "linux" ];
      };

      security.wrappers.nix-ccache.enable = false;

      nix.settings.extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
    };
}
