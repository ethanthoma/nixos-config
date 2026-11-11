{
  config,
  pkgs,
  lib,
  ...
}:
let
  skill_names = [
    "bend-development"
    "caveman-commit"
    "context-efficient-development"
    "gitignore-allowlist"
    "invariant-driven-testing"
    "minimize-complexity"
    "performance-engineering"
    "plain-technical-prose"
    "webgpu-rendering"
  ];
in
{
  home.activation.skills-config =
    (import ../../_lib/mutable-config.nix {
      inherit pkgs lib;
      homeDirectory = config.home.homeDirectory;
    })
      {
        name = "skills-config";
        repoUrl = "https://github.com/ethanthoma/skills.git";
        configPath = ".local/share/skills";
      };

  xdg.configFile = lib.mkMerge (
    map (
      name:
      let
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/share/skills/${name}";
      in
      {
        "agents/skills/${name}" = { inherit source; };
        "codex/skills/${name}" = { inherit source; };
        "pi/skills/${name}" = { inherit source; };
      }
    ) skill_names
  );
}
