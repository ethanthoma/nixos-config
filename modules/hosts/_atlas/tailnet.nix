{ config, ... }:

let
  values = [
    "tailnet_domain"
    "atlas_address"
    "desktop_address"
    "mullvad_exit_first"
    "mullvad_exit_second"
  ];
  placeholder = config.sops.placeholder;
in
{
  # Tailscale addresses stay out of this public repository: they are sops-encrypted, so Nix never sees them. Units
  # that need one load this environment file and let systemd expand ${ATLAS_ADDRESS} and friends at start.
  sops.secrets = builtins.listToAttrs (
    map (name: {
      inherit name;
      value.sopsFile = ./secrets/tailnet.yaml;
    }) values
  );

  sops.templates."tailnet.env".content = ''
    TAILNET_DOMAIN=${placeholder.tailnet_domain}
    ATLAS_ADDRESS=${placeholder.atlas_address}
    DESKTOP_ADDRESS=${placeholder.desktop_address}
    EXIT_FIRST=${placeholder.mullvad_exit_first}
    EXIT_SECOND=${placeholder.mullvad_exit_second}
  '';
}
