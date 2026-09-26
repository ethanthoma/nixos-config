{ inputs, ... }:
{
  flake.homeManagerModules.claude =
    { pkgs, ... }:
    {
      home.packages = [ inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      home.sessionVariables = {
        ENABLE_LSP_TOOL = "1";
      };

      # One instruction file for every agent and host; atlas links the same file from this repo.
      xdg.configFile."claude/CLAUDE.md".source = ./AGENTS.md;
    };
}
