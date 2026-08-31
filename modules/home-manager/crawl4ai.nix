{ ... }:
{
  flake.homeManagerModules.crawl4ai =
    { lib, pkgs, ... }:
    let
      endpoint = "http://127.0.0.1:11235/mcp/sse";

      # Every client authenticates to the loopback crawl4ai server with the
      # token the crawl4ai NixOS module generates, so it is exported once here
      # instead of being sourced by each client's launcher. An unreadable file
      # just means those MCP servers fail to authenticate.
      export_token = ''
        if [ -r /persist/crawl4ai.env ]; then
          set -a
          . /persist/crawl4ai.env
          set +a
        fi
      '';

      # Claude Code speaks SSE directly. Codex 0.149 speaks only stdio and
      # streamable HTTP, and crawl4ai serves neither, so codex gets a stdio
      # client bridged onto the same SSE endpoint. Reads the token itself so
      # it holds regardless of how codex was launched.
      stdio_bridge = pkgs.writeShellApplication {
        name = "crawl4ai-mcp-stdio";
        runtimeInputs = [ pkgs.mcp-proxy ];
        text = ''
          if [ ! -r /persist/crawl4ai.env ]; then
            echo "crawl4ai token unreadable at /persist/crawl4ai.env" >&2
            exit 1
          fi

          # shellcheck source=/dev/null
          . /persist/crawl4ai.env

          exec mcp-proxy \
            --transport sse \
            -H Authorization "Bearer ''${CRAWL4AI_API_TOKEN:?token missing from /persist/crawl4ai.env}" \
            ${endpoint}
        '';
      };
    in
    {
      home.packages = [ stdio_bridge ];

      # Home Manager sources hm-session-vars.sh from ~/.profile only, so a
      # terminal that spawns a non-login interactive shell would otherwise
      # start its clients with the token unset.
      home.sessionVariablesExtra = export_token;
      programs.bash.initExtra = lib.mkAfter export_token;
    };
}
