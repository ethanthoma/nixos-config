{ ... }:
{
  flake.nixosModules.ssh =
    { ... }:
    {
      # gpg-agent (incl. SSH support) is managed in home-manager (gpg.nix) so it
      # can live at an XDG homedir with matching socket paths — see that module.
      services.openssh.enable = true;

      # Pinned tailnet host keys: BatchMode sshes (codex's atlas credential
      # fetch, nix remote builds) fail hard on unknown hosts, so unpinned
      # keys break them silently after a known_hosts rewrite.
      programs.ssh.knownHosts.atlas.publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+AwVoBjO9+SG/Y6DtZ8jTPNh64uUdcfP+dbUh/DOWZ";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };
    };
}
