{ ... }:
{
  flake.homeManagerModules.secretspec =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.secretspec ];

      # Default the global provider to `keyring`, which on Linux is the
      # freedesktop Secret Service — here that's KeePassXC (see keepassxc.nix),
      # so secrets resolve from the YubiKey-backed vault. Declarative + read-only
      # so a fresh host already points at the vault; per-project secret
      # declarations live in each repo's own secretspec.toml.
      xdg.configFile."secretspec/config.toml".text = ''
        [defaults]
        provider = "keyring"
        profile = "default"
      '';
    };
}
