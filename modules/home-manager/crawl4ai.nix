{ ... }:
{
  flake.homeManagerModules.crawl4ai =
    { lib, ... }:
    let
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
    in
    {
      # Home Manager sources hm-session-vars.sh from ~/.profile only, so a
      # terminal that spawns a non-login interactive shell would otherwise
      # start its clients with the token unset.
      home.sessionVariablesExtra = export_token;
      programs.bash.initExtra = lib.mkAfter export_token;
    };
}
