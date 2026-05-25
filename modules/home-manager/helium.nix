{ inputs, ... }:
{
  flake.homeManagerModules.helium =
    { ... }:
    {
      imports = [ inputs.helium-flake.homeModules.default ];

      programs.helium = {
        enable = true;
        flags = [ "--ozone-platform-hint=auto" ];
      };
    };
}
