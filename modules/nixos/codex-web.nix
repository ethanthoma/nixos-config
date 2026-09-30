{ inputs, ... }:
{
  # Serves this machine's Codex and Claude sessions to codex-web on atlas
  # (github.com/gauge-numerics/codex-web): the Codex app-server and the Claude
  # shim, from the store, listening only on the host's Tailscale address, which
  # each host sets along with anything else host-specific.
  flake.nixosModules.codex-web =
    { pkgs, ... }:
    let
      username = "ethanthoma";
      home = "/home/${username}";
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      imports = [ inputs.codex-web.nixosModules.session-host ];

      services.codex-web-host = {
        enable = true;
        user = username;
        # The plain CLI, not the codex-atlas-wrapper home-manager puts on PATH:
        # the app-server needs no provider keys to read and run sessions.
        codex.package = inputs.codex-cli.packages.${system}.default;
        # The folders home-manager's xdg.nix points CODEX_HOME and
        # CLAUDE_CONFIG_DIR at, so terminal sessions show up too.
        codex.home = "${home}/.config/codex";
        claude.package = inputs.claude-code.packages.${system}.default;
        claude.configDir = "${home}/.config/claude";
      };
    };
}
