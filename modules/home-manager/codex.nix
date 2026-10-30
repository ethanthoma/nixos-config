{ inputs, ... }:
{
  flake.homeManagerModules.codex =
    { config, pkgs, ... }:
    let
      codex = inputs.codex-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
      codex_wrapper = pkgs.writeShellApplication {
        name = "codex-wrapper";
        runtimeInputs = [
          pkgs.secretspec
        ];
        text = ''
          # Only the `glm` profile needs this, so a locked vault must not take
          # down every codex launch; codex reports the missing env_key itself if
          # that profile is actually selected.
          openrouter_api_key="$(
            secretspec get OPENROUTER_API_KEY \
              -f "${config.xdg.configHome}/secretspec/secretspec.toml" \
              --reason "codex launch: OpenRouter provider credential" 2>/dev/null
          )" || openrouter_api_key=""

          if [ -n "$openrouter_api_key" ]; then
            export OPENROUTER_API_KEY="$openrouter_api_key"
          else
            echo "OpenRouter credential unavailable; the glm profile will not work." >&2
          fi

          exec ${codex}/bin/codex "$@"
        '';
      };
      codex_package = pkgs.runCommand "codex" { } ''
        mkdir -p "$out/bin"
        ln -s ${codex_wrapper}/bin/codex-wrapper "$out/bin/codex"
        ln -s ${codex}/share "$out/share"
      '';
    in
    {
      home.packages = [
        codex_package
        pkgs.chatgpt
      ];

      home.sessionVariables = {
        CODEX_HOME = "${config.xdg.configHome}/codex";
      };

      xdg.configFile."codex/AGENTS.md".source = ./AGENTS.md;
    };
}
