{ inputs, ... }:
{
  flake.homeManagerModules.codex =
    { config, pkgs, ... }:
    let
      codex = inputs.codex-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
      codex_wrapper = pkgs.writeShellApplication {
        name = "codex-atlas-wrapper";
        runtimeInputs = [ pkgs.openssh ];
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
          exec ${codex}/bin/codex "$@"
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
