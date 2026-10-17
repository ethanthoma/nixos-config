{
  inputs,
  pkgs,
  username,
  ...
}:

let
  agent_memory = pkgs.callPackage ./agent-memory { };
  pi = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = [
    pkgs.bottom
    pi
    agent_memory
  ];
  home.sessionPath = [ "/home/${username}/.local/bin" ];

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # One instruction file for Claude and Codex, shared with the surface.
  home.file.".claude/CLAUDE.md".source = ../../home-manager/AGENTS.md;
  home.file.".codex/AGENTS.md".source = ../../home-manager/AGENTS.md;
  home.file.".local/bin/agent-memory" = {
    source = "${agent_memory}/bin/agent-memory";
    force = true;
  };
  home.file.".local/bin/pi" = {
    source = "${pi}/bin/pi";
    force = true;
  };
  home.file.".pi/agent/extensions/agent-memory.ts" = {
    source = pkgs.writeText "pi-agent-memory.ts" (
      builtins.replaceStrings [ "@AGENT_MEMORY_BIN@" ] [ "${agent_memory}/bin/agent-memory" ] (
        builtins.readFile ./pi-agent-memory.ts
      )
    );
    force = true;
  };

  programs.bash.enable = true;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    tmux.enableShellIntegration = true;
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    withRuby = true;
    withPython3 = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;
    settings = {
      user = {
        name = "Ethan Thoma";
        email = "ethanthoma@gmail.com";
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      alias = {
        ci = "commit";
        co = "checkout";
        s = "status";
      };
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      safe.directory = "/etc/nixos";
      commit.gpgsign = true;
      gpg.format = "ssh";
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [ "--cmd cd" ];
  };
}
