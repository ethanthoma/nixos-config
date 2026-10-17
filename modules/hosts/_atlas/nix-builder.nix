{ pkgs, ... }:
{
  # Remote builder for the surface laptop (its nix-daemon connects over tailscale as nix-builder).
  # The client key lives on the surface at ~/.ssh/nix-builder; mirror a regenerated pubkey here.
  users.groups.nix-builder = { };

  users.users.nix-builder = {
    isSystemUser = true;
    group = "nix-builder";
    home = "/var/lib/nix-builder";
    createHome = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSubLhT+JvGRAxg0zCB41xClCR0UB+xul8IM30d8gd5 surface-nix-builder"
    ];
  };

  # Trusted so the client can copy derivations and outputs both ways.
  nix.settings.trusted-users = [ "nix-builder" ];
}
