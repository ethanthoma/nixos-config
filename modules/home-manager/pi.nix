{ inputs, self, ... }:
{
  flake.homeManagerModules.pi =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      piPackage = inputs.pi.packages.${system}.default.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          patch -p1 -d "$out/lib/pi/node_modules" < ${./patches/pi-ui.patch}

          substituteInPlace "$out/bin/pi" \
            --replace-fail '/dist/bundle/cli.js' '/dist/cli.js'

          substituteInPlace \
            "$out/lib/pi/node_modules/@earendil-works/pi-coding-agent/dist/modes/interactive/components/model-selector.js" \
            --replace-fail \
              'this.listContainer.addChild(new Text(line, 0, 0));' \
              'this.listContainer.addChild(new Text(isSelected ? theme.bg("selectedBg", line) : line, 0, 0));'
        '';
      });
      matterstateCloudConfig = "${config.xdg.configHome}/gcloud-matterstate";
      matterstatePi = pkgs.runCommand "pi-matterstate" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        mkdir -p "$out/bin"
        makeWrapper ${piPackage}/bin/pi "$out/bin/pi-matterstate" \
          --unset GOOGLE_CLOUD_API_KEY \
          --unset GEMINI_API_KEY \
          --set GOOGLE_APPLICATION_CREDENTIALS ${lib.escapeShellArg "${matterstateCloudConfig}/application_default_credentials.json"} \
          --set CLOUDSDK_CONFIG ${lib.escapeShellArg matterstateCloudConfig} \
          --set GOOGLE_CLOUD_PROJECT ultimate-rig-515507-e9 \
          --set GOOGLE_CLOUD_QUOTA_PROJECT ultimate-rig-515507-e9 \
          --set GOOGLE_CLOUD_LOCATION global \
          --set PI_CODING_AGENT_DIR ${lib.escapeShellArg "${config.xdg.configHome}/pi-matterstate"} \
          --add-flags '--provider google-vertex --model gemini-4-neon'
        makeWrapper ${pkgs.google-cloud-sdk}/bin/gcloud "$out/bin/gcloud-matterstate" \
          --unset GOOGLE_APPLICATION_CREDENTIALS \
          --set CLOUDSDK_CONFIG ${lib.escapeShellArg matterstateCloudConfig} \
          --set CLOUDSDK_CORE_PROJECT ultimate-rig-515507-e9
      '';
    in
    {
      imports = [ self.homeManagerModules.pi-settings ];
      home.packages = [
        piPackage
        matterstatePi
      ];

      xdg.configFile = {
        "pi-matterstate/AGENTS.md".source = ./AGENTS.md;
        "pi-matterstate/extensions/pi-goal".source = inputs.pi-goal;
        "pi-matterstate/models.json".text = builtins.toJSON {
          providers.google-vertex.modelOverrides."gemini-4-neon".contextWindow = 256000;
        };

        "pi/AGENTS.md".source = ./AGENTS.md;
        "pi/extensions/pi-goal".source = inputs.pi-goal;
        "pi/models.json".text = builtins.toJSON {
          providers.google-vertex.modelOverrides."gemini-4-neon" = {
            contextWindow = 256000;
          };
          providers.morph = {
            name = "Morph";
            baseUrl = "https://api.morphllm.com/v1";
            api = "openai-completions";
            apiKey = "!${pkgs.coreutils}/bin/cat ${lib.escapeShellArg "${config.xdg.configHome}/pi/morph-api-key"}";
            authHeader = true;
            compat = {
              maxTokensField = "max_tokens";
              supportsDeveloperRole = false;
              supportsReasoningEffort = true;
              supportsStore = false;
              thinkingFormat = "openai";
            };
            models = [
              {
                id = "morph-dsv41flash";
                name = "Morph DeepSeek V4.1 Flash";
                reasoning = true;
                input = [
                  "text"
                  "image"
                ];
                contextWindow = 1048576;
                maxTokens = 131072;
                cost = {
                  input = 0.12;
                  output = 0.8;
                  cacheRead = 0.008;
                  cacheWrite = 0;
                };
                thinkingLevelMap = {
                  off = "none";
                  minimal = "minimal";
                  low = "low";
                  medium = "high";
                  high = "high";
                  xhigh = "xhigh";
                  max = "max";
                };
              }
            ];
          };
        };

      };

      home.sessionVariables = {
        PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi";
      };
    };

  flake.homeManagerModules.pi-settings =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Pi writes runtime state here, so merge defaults instead of linking a read-only file.
      home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings=${lib.escapeShellArg "${config.xdg.configHome}/pi/settings.json"}
        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          mkdir -p "$(dirname "$settings")"
          temporary=$(mktemp "$settings.XXXXXX")
          if ${pkgs.jq}/bin/jq --slurp '
            (.[0] // {}) + {
              defaultProvider: "openai",
              defaultModel: "gpt-6.1-sol",
              defaultThinkingLevel: "low",
              defaultTools: ["+codemode"]
            } | .compaction.enabled = true
          ' "$([ -f "$settings" ] && printf '%s' "$settings" || printf /dev/null)" > "$temporary"; then
            mv "$temporary" "$settings"
          else
            rm -f "$temporary"
            exit 1
          fi
        fi
      '';
    };
}
