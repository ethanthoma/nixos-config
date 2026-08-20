{ ... }:
{
  flake.nixosModules.minecraft-terra =
    { pkgs, ... }:
    let
      dir = "/var/lib/minecraft-terra";
      jre = pkgs.temurin-jre-bin-17;
      forgeArgs = "@libraries/net/minecraftforge/forge/1.20.1-47.4.21/unix_args.txt";
      aikarFlags = [
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=40"
        "-XX:G1HeapRegionSize=8M"
        "-XX:G1ReservePercent=20"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=15"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
        "-Dusing.aikars.flags=https://mcflags.emc.gs"
        "-Daikars.new.flags=true"
      ];
      mct = pkgs.writeShellScriptBin "mct" ''
        export MCRCON_PASS="$(sudo grep -oP '(?<=^rcon.password=).*' ${dir}/server.properties)"
        exec ${pkgs.mcrcon}/bin/mcrcon -H 127.0.0.1 -P 25576 "$*"
      '';
    in
    {
      environment.systemPackages = [ mct ];

      networking.firewall.allowedTCPPorts = [ 25566 ];

      systemd.services.minecraft-terra = {
        description = "Terra Industria (Forge 1.20.1) Minecraft server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = "${dir}/world/level.dat";
        serviceConfig = {
          User = "minecraft";
          Group = "minecraft";
          WorkingDirectory = dir;
          ExecStart = "${jre}/bin/java -Xms8G -Xmx8G ${toString aikarFlags} ${forgeArgs} nogui";
          Restart = "on-failure";
          RestartSec = 15;
          TimeoutStopSec = 120;
          SuccessExitStatus = "0 143";
        };
      };

      systemd.services.minecraft-terra-backup = {
        description = "Hardlinked snapshot of the Terra Industria world";
        path = [
          pkgs.rsync
          pkgs.mcrcon
          pkgs.gnugrep
          pkgs.coreutils
          pkgs.findutils
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          dir=${dir}
          dest=/var/lib/minecraft-terra-backups
          [ -f "$dir/world/level.dat" ] || exit 0
          mkdir -p "$dest"
          pass="$(grep -oP '(?<=^rcon.password=).*' "$dir/server.properties")"
          rcon() { mcrcon -H 127.0.0.1 -P 25576 -p "$pass" "$1" || true; }
          rcon save-off
          rcon "save-all flush"
          sleep 5
          ts="$(date +%Y%m%d-%H%M)"
          latest="$(ls -1d "$dest"/snap-* 2>/dev/null | sort | tail -1 || true)"
          rsync -a ''${latest:+--link-dest="$latest"} "$dir/world/" "$dest/snap-$ts/"
          rcon save-on
          ls -1d "$dest"/snap-* | sort | head -n -48 | xargs -r rm -rf
        '';
      };

      systemd.timers.minecraft-terra-backup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
          RandomizedDelaySec = 300;
        };
      };
    };
}
