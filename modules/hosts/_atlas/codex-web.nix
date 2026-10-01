{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  # Sessions that run on atlas itself. Both daemons listen on loopback only; codex-web on this host is their sole client.
  codex_port = 46210;
  claude_port = 46211;
  web_port = 8090;
  home = "/home/${username}";
  # Tracked flakes rather than nixpkgs, which lags upstream releases by weeks. Same sources as the surface.
  system = pkgs.stdenv.hostPlatform.system;
  codex = inputs.codex-cli.packages.${system}.default;
  claude-code = inputs.claude-code.packages.${system}.default;
in
{
  sops.templates."codex-web-tailnet.env".content = ''
    LISTEN_ADDRESS=${config.sops.placeholder.atlas_address}
    DESKTOP_CODEX_URL=ws://${config.sops.placeholder.desktop_address}:46210
    DESKTOP_CLAUDE_URL=http://${config.sops.placeholder.desktop_address}:46211
    WEB_HEALTH_URL=http://${config.sops.placeholder.atlas_address}:${toString web_port}/
  '';

  users.users.codex-web = {
    isSystemUser = true;
    group = "codex-web";
  };
  users.groups.codex-web = { };

  # On PATH so the local Codex and Claude logins (`codex login`, `claude`) use the same builds as the services.
  environment.systemPackages = [
    codex
    claude-code
  ];

  # The app-server refuses to start when CODEX_HOME is missing, which it is until the first `codex login`.
  systemd.tmpfiles.rules = [
    "d ${home}/.codex 0700 ${username} users -"
    # Release directories belong to the deploy user. Z also hands over releases created by earlier root deploys.
    "Z /var/lib/codex-web-releases - codex-web-deploy codex-web-deploy -"
    "d /var/lib/claude-shim-releases 0755 codex-web-deploy codex-web-deploy -"
  ];

  systemd.services.codex-web = {
    description = "Mobile web client for Codex and Claude sessions on the desktop and atlas";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/var/lib/codex-web/server.js";
    path = [ pkgs.imagemagick ];
    serviceConfig = {
      ExecStart = "${pkgs.nodejs_22}/bin/node server.js";
      WorkingDirectory = "/var/lib/codex-web";
      # Session history snapshots so the UI stays readable while a host is down.
      StateDirectory = "codex-web-cache";
      StateDirectoryMode = "0700";
      # Holds WEB_TOKEN and the <HOST>_<BACKEND>_TOKEN secrets.
      EnvironmentFile = [
        "/var/lib/codex-web.env"
        config.sops.templates."codex-web-tailnet.env".path
      ];
      Environment = [
        "PORT=${toString web_port}"
        "HISTORY_CACHE_DIRECTORY=/var/lib/codex-web-cache"
        "HOSTS=desktop:Desktop,atlas:Atlas"
        "DESKTOP_CODEX_PROJECTS_ROOT=/home/ethanthoma/projects"
        "ATLAS_CODEX_URL=ws://127.0.0.1:${toString codex_port}"
        "ATLAS_CODEX_PROJECTS_ROOT=${home}/projects"
        "ATLAS_CLAUDE_URL=http://127.0.0.1:${toString claude_port}"
      ];
      User = "codex-web";
      Group = "codex-web";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.services.codex-app-server = {
    description = "Codex app-server for codex-web sessions on atlas";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'umask 077; printf %%s \"$CODEX_TOKEN\" > /run/codex-app-server/token'";
      ExecStart = "${codex}/bin/codex app-server --listen ws://127.0.0.1:${toString codex_port} --ws-auth capability-token --ws-token-file /run/codex-app-server/token";
      EnvironmentFile = "/var/lib/codex-app-server.env";
      Environment = "CODEX_HOME=${home}/.codex";
      User = username;
      Group = "users";
      WorkingDirectory = home;
      RuntimeDirectory = "codex-app-server";
      RuntimeDirectoryMode = "0700";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
    };
  };

  systemd.services.claude-shim = {
    description = "Claude Code shim for codex-web sessions on atlas";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    # Deployed by codex-web-deploy; absent until its first run.
    unitConfig.ConditionPathExists = "/var/lib/claude-shim-releases/current/node_modules";
    # Claude's Bash tool runs commands with the service's PATH rather than a login shell (Codex uses `bash -lc`), so
    # give it the PATH a login session on atlas gets instead of the minimal systemd one.
    environment.PATH = lib.mkForce (
      lib.concatStringsSep ":" [
        "/run/wrappers/bin"
        "${home}/.nix-profile/bin"
        "${home}/.local/state/nix/profile/bin"
        "/etc/profiles/per-user/${username}/bin"
        "/nix/var/nix/profiles/default/bin"
        "/run/current-system/sw/bin"
      ]
    );
    serviceConfig = {
      ExecStart = "${pkgs.nodejs_22}/bin/node shim.js";
      WorkingDirectory = "/var/lib/claude-shim-releases/current";
      EnvironmentFile = "/var/lib/claude-shim.env";
      Environment = [
        "LISTEN_ADDRESS=127.0.0.1"
        "PORT=${toString claude_port}"
        "CLAUDE_BIN=${claude-code}/bin/claude"
        "PROJECTS_ROOT=${home}/projects"
      ];
      # The shim must use the subscription login, never API billing.
      UnsetEnvironment = "ANTHROPIC_API_KEY";
      User = username;
      Group = "users";
      Restart = "on-failure";
      RestartSec = 5;
      # Agents here administer atlas: they edit /etc/nixos and run sudo (wheel needs no password) for
      # nixos-rebuild and systemctl. NoNewPrivileges would block sudo and ProtectSystem would mount / read-only, so
      # both stay off; the rollback is a previous system generation.
      NoNewPrivileges = false;
      PrivateTmp = true;
      ProtectSystem = false;
    };
    # Restarting the shim ends every running agent session, including the one that ran the switch; restart it by
    # hand when no session is working.
    restartIfChanged = false;
  };

  # Pull deploy. Every minute this fixed bootstrap fetches main and runs deploy/deploy.sh from that commit, so the
  # deploy logic ships on push like everything else. Only this file needs `nixos-rebuild switch`, and it should rarely
  # change: keep the bootstrap and the environment below stable. Nothing is exposed and GitHub holds no secrets; atlas
  # reads the repo with its own read-only deploy key.
  #
  # The deploy runs as codex-web-deploy, not root. It owns the release directories and may restart codex-web and
  # claude-shim through polkit, which is no more than a push to main already grants.
  users.users.codex-web-deploy = {
    isSystemUser = true;
    group = "codex-web-deploy";
    # npm keeps its cache under the home directory.
    home = "/var/lib/codex-web-deploy";
  };
  users.groups.codex-web-deploy = { };

  systemd.services.codex-web-deploy = {
    description = "Pull, check, and deploy codex-web from GitHub";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      DEPLOY_REPOSITORY = "git@github.com:gauge-numerics/codex-web.git";
      DEPLOY_BRANCH = "main";
      # Pinned rather than trusted on first use. From https://api.github.com/meta.
      DEPLOY_KNOWN_HOSTS = "${pkgs.writeText "github-known-hosts" ''
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
      ''}";
      RELEASES_DIRECTORY = "/var/lib/codex-web-releases";
      SHIM_RELEASES_DIRECTORY = "/var/lib/claude-shim-releases";
      SHIM_URL = "http://127.0.0.1:${toString claude_port}";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "codex-web-deploy";
      Group = "codex-web-deploy";
      ExecStart = lib.getExe (
        pkgs.writeShellApplication {
          name = "codex-web-deploy";
          # A generous toolbox, so deploy/deploy.sh can change on push without a rebuild.
          runtimeInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.curl
            pkgs.diffutils
            pkgs.findutils
            pkgs.gawk
            pkgs.git
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gnutar
            pkgs.gzip
            pkgs.jq
            pkgs.nodejs_22
            pkgs.openssh
            pkgs.systemd
            pkgs.util-linux
          ];
          text = ''
            key=$STATE_DIRECTORY/deploy_key
            repository=$STATE_DIRECTORY/repository.git
            build=$RUNTIME_DIRECTORY/build
            if [[ ! -f "$key" ]]; then
              ssh-keygen -q -t ed25519 -N "" -C "codex-web-deploy@atlas" -f "$key"
              echo "generated $key.pub; add it to GitHub as a read-only deploy key:"
              cat "$key.pub"
            fi
            export GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$DEPLOY_KNOWN_HOSTS"
            if [[ ! -d "$repository" ]]; then
              git init --quiet --bare "$repository"
            fi
            git --git-dir="$repository" fetch --quiet --no-tags "$DEPLOY_REPOSITORY" \
              "+refs/heads/$DEPLOY_BRANCH:refs/heads/$DEPLOY_BRANCH"
            target=$(git --git-dir="$repository" rev-parse --verify "refs/heads/$DEPLOY_BRANCH^{commit}")
            rm -rf "$build"
            mkdir "$build"
            git --git-dir="$repository" archive "$target" | tar --extract --directory="$build"
            export BUILD_DIRECTORY=$build
            export DEPLOY_REPOSITORY_GIT_DIR=$repository
            exec bash "$build/deploy/deploy.sh" "$target"
          '';
        }
      );
      # CLAUDE_TOKEN, to ask the shim whether a turn is running before restarting it.
      EnvironmentFile = [
        "/var/lib/claude-shim.env"
        # WEB_HEALTH_URL, which holds the Tailscale address.
        config.sops.templates."codex-web-tailnet.env".path
      ];
      StateDirectory = "codex-web-deploy";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "codex-web-deploy";
      RuntimeDirectoryMode = "0700";
      TimeoutStartSec = "15min";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/var/lib/codex-web-releases"
        "/var/lib/claude-shim-releases"
      ];
    };
  };

  systemd.timers.codex-web-deploy = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitInactiveSec = "1min";
    };
  };

  # Agents run inside claude-shim, whose NoNewPrivileges blocks sudo, but systemctl asks systemd over D-Bus, so these
  # rules work there. The login user may start a deploy now instead of waiting for the timer; the deploy user may
  # restart the two services it deploys. Nothing else.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id !== "org.freedesktop.systemd1.manage-units") return polkit.Result.NOT_HANDLED;
      var unit = action.lookup("unit");
      var verb = action.lookup("verb");
      if (subject.user === "${username}") {
        if (unit === "codex-web-deploy.service" && verb === "start") return polkit.Result.YES;
      }
      if (subject.user === "codex-web-deploy") {
        if (verb !== "restart") return polkit.Result.NOT_HANDLED;
        if (unit === "codex-web.service") return polkit.Result.YES;
        if (unit === "claude-shim.service") return polkit.Result.YES;
      }
      return polkit.Result.NOT_HANDLED;
    });
  '';

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ web_port ];
}
