{
  config,
  inputs,
  pkgs,
  username,
  ...
}:

let
  agent_memory = pkgs.callPackage ../../_packages/agent-memory { };
  pi = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  imports = [
    ../../home-manager/_agent-cache
    ../../home-manager/_agent-skills
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = [
    pkgs.bottom
    pi
  ];
  home.sessionPath = [ "/home/${username}/.local/bin" ];
  home.sessionVariables = {
    CODEX_HOME = "${config.xdg.configHome}/codex";
    PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi";
  };

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  xdg.configFile."codex/AGENTS.md".source = ../../home-manager/AGENTS.md;
  home.file.".local/bin/pi" = {
    source = "${pi}/bin/pi";
    force = true;
  };
  xdg.configFile."pi/extensions/agent-memory.ts" = {
    source = pkgs.writeText "pi-agent-memory.ts" (
      builtins.replaceStrings [ "@AGENT_MEMORY_BIN@" ] [ "${agent_memory}/bin/agent-memory" ] (
        builtins.readFile ./pi-agent-memory.ts
      )
    );
    force = true;
  };

}
