{ ... }:
{
  flake.nixosModules.crawl4ai =
    { pkgs, ... }:
    {
      # 0.9.x authenticates every route but /health and /token. Without
      # CRAWL4AI_API_TOKEN the server mints an ephemeral token per start, which
      # no client can be configured against, so one is generated on first boot
      # into /persist rather than the world-readable store, and left alone
      # afterwards. Group `users` so the clients can read it back.
      systemd.services.crawl4ai-token = {
        before = [ "podman-crawl4ai.service" ];
        requiredBy = [ "podman-crawl4ai.service" ];

        unitConfig = {
          ConditionPathExists = "!/persist/crawl4ai.env";
          RequiresMountsFor = "/persist";
        };

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0027";
        };

        script = ''
          printf 'CRAWL4AI_API_TOKEN=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)" \
            > /persist/crawl4ai.env
          chown root:users /persist/crawl4ai.env
        '';
      };

      virtualisation.oci-containers.containers.crawl4ai = {
        image = "docker.io/unclecode/crawl4ai:0.9.2";

        environmentFiles = [ "/persist/crawl4ai.env" ];

        # crawl4ai binds 127.0.0.1 from config.yml, which published ports
        # cannot reach. Host networking makes the container's loopback the
        # host's, so it serves 127.0.0.1:11235 and stays off the LAN without
        # mounting an override config.
        extraOptions = [
          "--network=host"
          "--shm-size=1g"
        ];
      };
    };
}
