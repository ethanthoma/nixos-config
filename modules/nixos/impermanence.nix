{ inputs, ... }:
{
  flake.nixosModules.impermanence =
    { ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      services.openssh.hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];

      environment.persistence."/persist" = {
        hideMounts = true;

        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd"
          "/var/lib/bluetooth"
          "/var/lib/iwd"
          "/var/lib/fwupd"
          "/var/lib/containers"
          "/var/lib/tailscale"
          "/etc/NetworkManager/system-connections"
        ];

        files = [
          "/etc/machine-id"
        ];
      };
    };
}
