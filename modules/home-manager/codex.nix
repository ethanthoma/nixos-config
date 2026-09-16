{ inputs, ... }:
{
  flake.homeManagerModules.codex =
    { config, pkgs, ... }:
    let
      codex = inputs.codex-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
      codex_wrapper = pkgs.writeShellApplication {
        name = "codex-atlas-wrapper";
        runtimeInputs = [
          pkgs.openssh
          pkgs.secretspec
        ];
        text = ''
          atlas_llm_api_key="$(
            ssh -o BatchMode=yes -o ConnectTimeout=5 atlas \
              "sudo -n sh -c 'set -a; . /var/lib/llama-server.env; printf \"%s\" \"\$LLAMA_API_KEY\"'"
          )"

          if [ -z "$atlas_llm_api_key" ]; then
            echo "Atlas LLM credential unavailable." >&2
            exit 1
          fi

          export ATLAS_LLM_API_KEY="$atlas_llm_api_key"

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

          codex_args=()
          for var in WAYLAND_DISPLAY XDG_RUNTIME_DIR; do
            value="''${!var:-}"
            if [ -n "$value" ]; then
              codex_args+=(-c "shell_environment_policy.set.$var=\"$value\"")
            fi
          done

          exec ${codex}/bin/codex "''${codex_args[@]}" "$@"
        '';
      };
      codex_atlas = pkgs.runCommand "codex" { } ''
        mkdir -p "$out/bin"
        ln -s ${codex_wrapper}/bin/codex-atlas-wrapper "$out/bin/codex"
        ln -s ${codex}/share "$out/share"
      '';
    in
    {
      home.packages = [ codex_atlas ];

      home.sessionVariables = {
        CODEX_HOME = "${config.xdg.configHome}/codex";
      };
    };
}
