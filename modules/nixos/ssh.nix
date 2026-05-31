{ ... }:
{
  flake.nixosModules.ssh =
    { ... }:
    {
      # gpg-agent (incl. SSH support) is managed in home-manager (gpg.nix) so it
      # can live at an XDG homedir with matching socket paths — see that module.
      services.openssh.enable = true;

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };
    };
}
