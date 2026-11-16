{ ... }:
{
  flake.homeManagerModules.xdg =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      home = config.home.homeDirectory;
      dataHome = "${home}/.local/share";
      stateHome = "${home}/.local/state";
      configHome = "${home}/.config";
      cacheHome = "${home}/.cache";
    in
    {
      xdg.enable = true;

      home.sessionVariables = {
        # Rust
        CARGO_HOME = "${dataHome}/cargo";
        RUSTUP_HOME = "${dataHome}/rustup";

        # Go
        GOPATH = "${dataHome}/go";

        # Node / npm
        NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
        npm_config_cache = "${cacheHome}/npm";
        npm_config_prefix = "${dataHome}/npm";
        NODE_REPL_HISTORY = "${stateHome}/node/repl_history";

        # Python
        PYTHONSTARTUP = "${configHome}/python/startup.py";

        # PostgreSQL (history -> XDG_STATE_HOME)
        PSQL_HISTORY = "${stateHome}/psql/history";

        # Cloud CLIs
        AWS_CONFIG_FILE = "${configHome}/aws/config";
        AWS_SHARED_CREDENTIALS_FILE = "${configHome}/aws/credentials";
        AZURE_CONFIG_DIR = "${configHome}/azure";
        DOCKER_CONFIG = "${configHome}/docker";

        # Haskell / OCaml / Elixir
        STACK_ROOT = "${dataHome}/stack";
        STACK_XDG = "1";
        OPAMROOT = "${dataHome}/opam";
        MIX_HOME = "${dataHome}/mix";
        HEX_HOME = "${dataHome}/hex";

        # Android
        ANDROID_USER_HOME = "${dataHome}/android";

        # wget
        WGETRC = "${configHome}/wget/wgetrc";

        # JS / Bun
        BUN_INSTALL = "${dataHome}/bun";

        # Infra / cloud
        PULUMI_HOME = "${dataHome}/pulumi";

        # ML toolchains
        KERAS_HOME = "${dataHome}/keras";
        TRITON_HOME = "${cacheHome}/triton";
        TRITON_CACHE_DIR = "${cacheHome}/triton/cache";

        # NVIDIA shader/compute caches (~/.nv holds both)
        CUDA_CACHE_PATH = "${cacheHome}/nv/ComputeCache";
        __GL_SHADER_DISK_CACHE_PATH = "${cacheHome}/nv/GLCache";

        # Claude Code
        CLAUDE_CONFIG_DIR = "${configHome}/claude";

        # OpenAI Codex CLI
        CODEX_HOME = "${configHome}/codex";

        # libX11 compiled-compose cache (default ~/.compose-cache)
        XCOMPOSECACHE = "${cacheHome}/compose";

        # Terraform (CHECKPOINT_DISABLE stops the checkpoint client writing ~/.terraform.d)
        CHECKPOINT_DISABLE = "1";
        TF_CLI_CONFIG_FILE = "${configHome}/terraform/terraformrc";
        TF_PLUGIN_CACHE_DIR = "${cacheHome}/terraform/plugins";

        # imageio downloaded plugin binaries
        IMAGEIO_USERDIR = "${dataHome}/imageio";
      };

      # systemd user services (and apps they launch) don't source the shell's
      # session vars, so anything that runs cargo from a unit would recreate
      # ~/.cargo. Mirror the rust paths into the systemd user environment too.
      systemd.user.sessionVariables = {
        CARGO_HOME = "${dataHome}/cargo";
        RUSTUP_HOME = "${dataHome}/rustup";
        CLAUDE_CONFIG_DIR = "${configHome}/claude";
      };

      programs.bash.historyFile = "${stateHome}/bash/history";
      programs.bash.initExtra = lib.mkAfter "export HISTFILE";

      xdg.configFile."wget/wgetrc".text = ''
        hsts-file = ${cacheHome}/wget/hsts
      '';

      # Reroute Python REPL history into XDG_STATE_HOME.
      xdg.configFile."python/startup.py".text = ''
        import atexit
        import os
        import readline

        state = os.environ.get(
            "XDG_STATE_HOME", os.path.expanduser("~/.local/state")
        )
        hist = os.path.join(state, "python", "history")
        os.makedirs(os.path.dirname(hist), exist_ok=True)
        try:
            readline.read_history_file(hist)
        except FileNotFoundError:
            pass
        atexit.register(readline.write_history_file, hist)
      '';

      # Migrate existing dotfile locations on switch. Only moves when the
      # destination does not exist, so re-runs are idempotent and data is
      # never overwritten.
      home.activation.migrateXdg = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        move() {
          local src="$1" dst="$2"
          if [ -e "$src" ] && [ ! -e "$dst" ]; then
            $DRY_RUN_CMD mkdir -p "$(dirname "$dst")"
            $DRY_RUN_CMD mv "$src" "$dst"
            echo "xdg: migrated $src -> $dst"
          elif [ -e "$src" ] && [ -e "$dst" ]; then
            echo "xdg: left $src untouched; $dst already exists (manual reconciliation needed)" >&2
          fi
        }

        # Preserve both trees when reconciling a previous partial Claude migration.
        # Never move a live session's files: it could recreate the legacy paths.
        if ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -x 'claude|.claude-unwrapp' >/dev/null; then
          echo "xdg: close Claude Code and activate again to migrate its legacy files" >&2
        else
          if [ -d "${home}/.claude" ] && [ -d "${configHome}/claude" ]; then
            if [ -z "''${DRY_RUN_CMD:-}" ]; then
              mkdir -p "${stateHome}/xdg-migration"
              backup=$(mktemp -d "${stateHome}/xdg-migration/claude.XXXXXXXX")
              chmod 700 "$backup"
              ${pkgs.rsync}/bin/rsync -a --update --backup \
                --backup-dir="$backup/overwritten" \
                "${home}/.claude/" "${configHome}/claude/"
              mv "${home}/.claude" "$backup/legacy"
              if [ -f "${home}/.claude.json" ]; then
                if [ -e "${configHome}/claude/.claude.json" ]; then
                  cp -a "${configHome}/claude/.claude.json" "$backup/config.claude.json"
                fi
                mv "${home}/.claude.json" "${configHome}/claude/.claude.json"
              fi
              echo "xdg: reconciled Claude config; originals preserved in $backup"
            else
              echo "xdg: would reconcile Claude config with a private backup"
            fi
          else
            move "${home}/.claude" "${configHome}/claude"
            move "${home}/.claude.json" "${configHome}/claude/.claude.json"
          fi
        fi

        move "${home}/.certs"             "${dataHome}/certificates"
        move "${home}/.cargo"             "${dataHome}/cargo"
        move "${home}/.rustup"            "${dataHome}/rustup"
        move "${home}/go"                 "${dataHome}/go"
        move "${home}/.gnupg"             "${dataHome}/gnupg"
        move "${home}/.stack"             "${dataHome}/stack"
        move "${home}/.opam"              "${dataHome}/opam"
        move "${home}/.mix"               "${dataHome}/mix"
        move "${home}/.hex"               "${dataHome}/hex"
        move "${home}/.android"           "${dataHome}/android"
        move "${home}/.npm"               "${cacheHome}/npm"

        move "${home}/.gmailctl"          "${configHome}/gmailctl"
        move "${home}/.aws"               "${configHome}/aws"
        move "${home}/.azure"             "${configHome}/azure"
        move "${home}/.docker"            "${configHome}/docker"
        move "${home}/.npmrc"             "${configHome}/npm/npmrc"

        move "${home}/.bash_history"      "${stateHome}/bash/history"
        move "${home}/.python_history"    "${stateHome}/python/history"
        move "${home}/.node_repl_history" "${stateHome}/node/repl_history"
        move "${home}/.psql_history"      "${stateHome}/psql/history"

        move "${home}/.bun"               "${dataHome}/bun"
        move "${home}/.pulumi"            "${dataHome}/pulumi"
        move "${home}/.keras"             "${dataHome}/keras"
        move "${home}/.codex"             "${configHome}/codex"
        move "${home}/.triton"            "${cacheHome}/triton"
        move "${home}/.nv"                "${cacheHome}/nv"
        move "${home}/.imageio"           "${dataHome}/imageio"

        $DRY_RUN_CMD mkdir -p "${cacheHome}/terraform/plugins"
        $DRY_RUN_CMD mkdir -p "${stateHome}/psql"
      '';
    };
}
