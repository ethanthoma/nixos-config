{ ... }:
{
  flake.nixosModules.keyd =
    { ... }:
    {
      services.keyd = {
        enable = true;
        keyboards.default = {
          ids = [ "*" ];
          settings.main.capslock = "C-space";
        };
      };
    };
}
