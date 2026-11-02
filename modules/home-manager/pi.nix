{ inputs, ... }:
{
  flake.homeManagerModules.pi =
    { config, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      piPackage = inputs.pi.packages.${system}.default.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          patch -p1 -d "$out/lib/pi/node_modules" < ${./patches/pi-ui.patch}

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

      home.sessionVariables = {
        PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi";
      };
    };
}
