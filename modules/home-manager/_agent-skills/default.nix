{ lib, ... }:
let
  skill_names = [
    "caveman-commit"
    "context-efficient-development"
    "invariant-driven-testing"
    "minimize-complexity"
    "performance-engineering"
    "webgpu-rendering"
  ];
in
{
  xdg.configFile = lib.mkMerge (
    map (
      name:
      let
        source = ./. + "/${name}";
      in
      {
        "agents/skills/${name}" = { inherit source; };
        "codex/skills/${name}" = { inherit source; };
        "pi/skills/${name}" = { inherit source; };
      }
    ) skill_names
  );
}
