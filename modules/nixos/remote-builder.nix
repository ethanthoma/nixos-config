{ ... }:
{
  # Distributed builds: the surface offloads to atlas and the desktop over tailscale.
  # The client key is imperative state (like hashedPasswordFile); recreate with:
  #   ssh-keygen -t ed25519 -N "" -C surface-nix-builder -f ~/.ssh/nix-builder
  # and mirror the new pubkey into remote-builder-host below and into atlas's
  # /etc/nixos/nix-builder.nix (atlas is configured outside this flake).
  flake.nixosModules.remote-builder-host =
    { pkgs, ... }:
    {
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
    };

  flake.nixosModules.remote-builder-client =
    { ... }:
    {
      nix.distributedBuilds = true;

      # Builders fetch substitutes themselves instead of pulling them
      # through the surface.
      nix.settings.builders-use-substitutes = true;

      # Atlas (32 cores, always on) is preferred; the desktop is often asleep,
      # and nix skips a builder it cannot reach.
      nix.buildMachines = [
        {
          hostName = "atlas";
          protocol = "ssh-ng";
          sshUser = "nix-builder";
          sshKey = "/home/ethanthoma/.ssh/nix-builder";
          system = "x86_64-linux";
          maxJobs = 4;
          speedFactor = 8;
          supportedFeatures = [
            "big-parallel"
            "kvm"
            "nixos-test"
            "benchmark"
          ];
        }
        {
          hostName = "desktop";
          protocol = "ssh-ng";
          sshUser = "nix-builder";
          sshKey = "/home/ethanthoma/.ssh/nix-builder";
          system = "x86_64-linux";
          maxJobs = 2;
          speedFactor = 2;
          supportedFeatures = [
            "big-parallel"
            "kvm"
            "nixos-test"
            "benchmark"
          ];
        }
      ];

      # nix-daemon sshes as root, whose known_hosts is empty; pin the
      # desktop's host key here (atlas's is pinned in ssh.nix). Host names
      # resolve through tailscale MagicDNS.
      programs.ssh.knownHosts.desktop.publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpqjo6UFyd20IcBENfg2eOKfOSEzMTsY3bt8cFvwX1X";
    };
}
