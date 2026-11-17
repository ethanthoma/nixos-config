{ inputs, ... }:
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
    in
    {
      home.packages = [ piPackage ];

      # Pi writes runtime state here, so merge defaults instead of linking a read-only file.
      home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings=${lib.escapeShellArg "${config.xdg.configHome}/pi/settings.json"}
        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          mkdir -p "$(dirname "$settings")"
          temporary=$(mktemp "$settings.XXXXXX")
          if ${pkgs.jq}/bin/jq --slurp '
            (.[0] // {}) + {
              defaultProvider: "openai",
              defaultModel: "gpt-6.2-sol",
              defaultThinkingLevel: "low",
              defaultTools: ["+codemode"]
            }
          ' "$([ -f "$settings" ] && printf '%s' "$settings" || printf /dev/null)" > "$temporary"; then
            mv "$temporary" "$settings"
          else
            rm -f "$temporary"
            exit 1
          fi
        fi
      '';

      xdg.configFile."pi/extensions/pi-goal".source = inputs.pi-goal;

      home.sessionVariables = {
        PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi";
      };
    };
}
