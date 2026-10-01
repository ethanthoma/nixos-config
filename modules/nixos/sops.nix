{ inputs, ... }:
{
  # Secrets live encrypted in secrets/ and decrypt at activation with the host's
  # ed25519 SSH key, which sops-nix finds through services.openssh.hostKeys.
  # Recipients are listed in .sops.yaml at the repo root.
  flake.nixosModules.sops =
    { config, pkgs, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops.defaultSopsFile = ../../secrets/nix.yaml;

      sops.secrets.github-token = { };

      # Lets nix fetch private GitHub inputs (codex-web) as root, which has no
      # SSH key. Wheel can read it so evaluating as the user works too. Nix skips
      # an unreadable !include, so other users like nix-builder are unaffected.
      sops.templates."nix-access-tokens.conf" = {
        content = "access-tokens = github.com=${config.sops.placeholder.github-token}";
        group = "wheel";
        mode = "0440";
      };

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-access-tokens.conf".path}
      '';

      environment.systemPackages = [ pkgs.sops ];
    };
}
