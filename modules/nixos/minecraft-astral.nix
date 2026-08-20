{ ... }:
{
  flake.nixosModules.minecraft-astral =
    { config, pkgs, ... }:
    let
      dir = "/var/lib/minecraft-astral";
      jre = pkgs.temurin-jre-bin-17;
      aikarFlags = [
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=40"
        "-XX:G1MaxNewSizePercent=50"
        "-XX:G1HeapRegionSize=16M"
        "-XX:G1ReservePercent=15"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=20"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
        "-Dusing.aikars.flags=https://mcflags.emc.gs"
        "-Daikars.new.flags=true"
      ];
      mc = pkgs.writeShellScriptBin "mc" ''
        export MCRCON_PASS="$(sudo grep -oP '(?<=^rcon.password=).*' ${dir}/server.properties)"
        exec ${pkgs.mcrcon}/bin/mcrcon -H 127.0.0.1 -P 25575 "$*"
      '';
    in
    {
      users.users.minecraft = {
        isSystemUser = true;
        group = "minecraft";
        home = dir;
      };
      users.groups.minecraft = { };

      environment.systemPackages = [
        pkgs.mcrcon
        mc
      ];

      sops.secrets."cloudflare-ddns-token" = { };

      networking.firewall.allowedTCPPorts = [ 25565 ];

      services.cloudflare-dyndns = {
        enable = true;
        apiTokenFile = config.sops.secrets."cloudflare-ddns-token".path;
        domains = [ "mc.ethanthoma.com" ];
        ipv4 = true;
        ipv6 = false;
      };

      systemd.services.minecraft-srv-record = {
        description = "Ensure the Cloudflare SRV record for the Minecraft server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [
          pkgs.curl
          pkgs.jq
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          LoadCredential = [ "cf:${config.sops.secrets."cloudflare-ddns-token".path}" ];
        };
        script = ''
          token="$(cat "$CREDENTIALS_DIRECTORY/cf")"
          api="https://api.cloudflare.com/client/v4"
          name="_minecraft._tcp.mc.ethanthoma.com"
          payload='{"type":"SRV","name":"_minecraft._tcp.mc.ethanthoma.com","ttl":1,"data":{"service":"_minecraft","proto":"_tcp","name":"mc.ethanthoma.com","priority":0,"weight":0,"port":25565,"target":"mc.ethanthoma.com"}}'
          zone="$(curl -fsS -H "Authorization: Bearer $token" "$api/zones?name=ethanthoma.com" | jq -r '.result[0].id')"
          id="$(curl -fsS -H "Authorization: Bearer $token" "$api/zones/$zone/dns_records?type=SRV&name=$name" | jq -r '.result[0].id // empty')"
          if [ -n "$id" ]; then
            curl -fsS -X PUT -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$api/zones/$zone/dns_records/$id" --data "$payload" >/dev/null
          else
            curl -fsS -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$api/zones/$zone/dns_records" --data "$payload" >/dev/null
          fi
        '';
      };

      systemd.services.minecraft-astral = {
        description = "Create: Astral (Fabric 1.18.2) Minecraft server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = "${dir}/server.jar";
        preStart = ''
          ${pkgs.gnused}/bin/sed -i \
            -e 's/^white-list=.*/white-list=true/' \
            -e 's/^enforce-whitelist=.*/enforce-whitelist=true/' \
            ${dir}/server.properties
        '';
        serviceConfig = {
          User = "minecraft";
          Group = "minecraft";
          WorkingDirectory = dir;
          ExecStart = "${jre}/bin/java -Xms12G -Xmx12G ${toString aikarFlags} -jar server.jar nogui";
          Restart = "on-failure";
          RestartSec = 15;
          TimeoutStopSec = 120;
          SuccessExitStatus = "0 143";
        };
      };
    };
}
