{ inputs, ... }:
{
  # DRAFT — not wired into any host yet. Activate only after the bcachefs
  # migration, when `/` is a wipe-on-boot subvolume and `/persist` + `/home`
  # are their own persistent subvolumes. See /etc/nixos/bcachefs-migration.md
  # for the format steps and the initrd rollback service that does the wipe.
  #
  # Style: wipe `/` only. `/home` is a separate persistent subvolume, so all
  # user state (syncthing identity, ~/keepass, browser profiles, game saves,
  # podman, gnupg/keyring) survives automatically — nothing to declare here.
  # Only system state that lives on the wiped root needs persisting.
  flake.nixosModules.impermanence =
    { ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # SSH host keys generate directly in /persist rather than being bind-mounted
      # over a wiped /etc/ssh — avoids the first-boot chicken-and-egg and keeps the
      # host identity stable (otherwise known_hosts breaks on every boot).
      services.openssh.hostKeys = [
        { path = "/persist/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
        { path = "/persist/etc/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
      ];

      environment.persistence."/persist" = {
        hideMounts = true;

        directories = [
          "/var/log" # journald history across boots
          "/var/lib/nixos" # uid/gid allocation map — without it users can be renumbered
          "/var/lib/systemd" # random-seed, coredumps, timer stamps
          "/var/lib/bluetooth" # paired devices
          "/var/lib/iwd" # wifi PSKs (networkmanager uses the iwd backend)
          "/var/lib/fwupd" # firmware update state
          "/var/lib/containers" # rootful podman images/volumes (podman.nix, dockerCompat)
          "/etc/NetworkManager/system-connections" # NM connection profiles
          "/etc/nixos" # this flake — lives on root, would be wiped otherwise
        ];

        # Deliberately NOT persisted — these /var/lib dirs exist today but are stale
        # leftovers from services no longer in the config, so the wipe just cleans them:
        #   docker          — replaced by podman (dockerCompat); /var/lib/docker is dead
        #   lightdm*        — replaced by greetd (hyprland.nix); greetd is stateless
        #   sops-nix/secrets — no sops config in the flake; regenerated if ever added
        #   NetworkManager-fortisslvpn — no VPN configured; connections live in the
        #                                persisted system-connections above anyway
        # gnupg/keyring already live under ~/.local/share (xdg.nix) → on /home, survive.

        files = [
          "/etc/machine-id" # stable journald/machine identity
        ];
      };
    };
}
