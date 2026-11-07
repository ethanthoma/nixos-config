{
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
  imports = [ ../../home-manager/_codex-skills ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = [
    pkgs.bottom
    pi
  ];
  home.sessionPath = [ "/home/${username}/.local/bin" ];

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.file.".codex/AGENTS.md".source = ../../home-manager/AGENTS.md;
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

}
