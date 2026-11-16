{
  config,
  pkgs,
  lib,
  ...
}:
let
  skill_names = [
    "ast-grep-policy"
    "bend-development"
    "caveman-commit"
    "code-style"
    "context-efficient-development"
    "gitignore-allowlist"
    "invariant-driven-testing"
    "minimize-complexity"
    "performance-engineering"
    "plain-technical-prose"
    "structural-reasoning"
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

  home.file = lib.genAttrs (map (name: ".claude/skills/${name}") skill_names) (path: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/share/skills/${builtins.baseNameOf path}";
  });

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
