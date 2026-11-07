{ config, ... }:
let
  cache_home = config.xdg.cacheHome;
  config_home = config.xdg.configHome;
in
{
  systemd.user.tmpfiles.rules = [
    "d ${cache_home}/codex/cache 0700 - - -"
    "d ${cache_home}/codex/plugins/cache 0700 - - -"
    "d ${cache_home}/pi 0700 - - -"
    "d ${config_home}/codex/plugins 0700 - - -"
    "d ${config_home}/pi 0700 - - -"
    "L ${config_home}/codex/cache - - - - ${cache_home}/codex/cache"
    "L ${config_home}/codex/models_cache.json - - - - ${cache_home}/codex/models_cache.json"
    "L ${config_home}/codex/plugins/cache - - - - ${cache_home}/codex/plugins/cache"
    "L ${config_home}/pi/models-store.json - - - - ${cache_home}/pi/models-store.json"
  ];
}
