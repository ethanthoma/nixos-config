{ ... }:
{
  flake.homeManagerModules.secretspec =
    { pkgs, ... }:
    {
      # secretspec ships no completion generator, so the script is hand-written
      # against its 0.19 CLI surface; bash-completion picks it up from the
      # profile's share/ directory via XDG_DATA_DIRS.
      home.packages = [
        pkgs.secretspec
        (pkgs.writeTextFile {
          name = "secretspec-bash-completion";
          destination = "/share/bash-completion/completions/secretspec";
          text = builtins.readFile ../_files/secretspec-completion.bash;
        })
      ];

      # Default the global provider to `keyring`, which on Linux is the
      # freedesktop Secret Service — here that's KeePassXC (see keepassxc.nix),
      # so secrets resolve from the YubiKey-backed vault. Declarative + read-only
      # so a fresh host already points at the vault; project-scoped secret
      # declarations still live in each repo's own secretspec.toml.
      xdg.configFile."secretspec/config.toml".text = ''
        [defaults]
        provider = "keyring"
        profile = "default"
      '';

      # Secrets used from more than one repo. Keyring items are namespaced as
      # secretspec/<project>/<profile>/<NAME>, so declaring one of these in a repo
      # manifest too would create a second, independently rotated copy. Discovery
      # stops at the first manifest above the cwd, so consumers pass `-f`.
      xdg.configFile."secretspec/secretspec.toml".text = ''
        [project]
        name = "home"
        revision = "1.0"

        [profiles.default]
        OPENROUTER_API_KEY = { description = "OpenRouter API key for delegated model runs (Codex glm profile)", required = true }
      '';
    };
}
