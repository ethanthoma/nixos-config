{ ... }:
{
  flake.nixosModules.k3s =
    { ... }:
    {
      services.k3s = {
        enable = true;
        role = "server";
        extraFlags = [
          "--write-kubeconfig-mode=0644"
          "--snapshotter=native"
        ];
      };

      networking.firewall.trustedInterfaces = [
        "cni0"
        "flannel.1"
      ];
    };
}
