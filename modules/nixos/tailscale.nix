{ ... }:
{
  flake.nixosModules.tailscale =
    { ... }:
    {
      services.tailscale.enable = true;
      services.tailscale.authKeyFile = "/persist/secrets/tailscale.key";
    };
}
