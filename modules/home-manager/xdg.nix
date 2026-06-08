{ ... }:
{
  flake.homeManagerModules.xdg =
    { config, lib, ... }:
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

        # Claude Code home (config, sessions, memory)
        CLAUDE_CONFIG_DIR = "${configHome}/claude";

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

        # OpenAI Codex CLI
        CODEX_HOME = "${configHome}/codex";

        # PulseAudio auth cookie
        PULSE_COOKIE = "${stateHome}/pulse/cookie";

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
      home.activation.migrateXdg = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        move() {
          local src="$1" dst="$2"
          if [ -e "$src" ] && [ ! -e "$dst" ]; then
            $DRY_RUN_CMD mkdir -p "$(dirname "$dst")"
            $DRY_RUN_CMD mv "$src" "$dst"
            echo "xdg: migrated $src -> $dst"
          fi
        }

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

        move "${home}/.aws"               "${configHome}/aws"
        move "${home}/.azure"             "${configHome}/azure"
        move "${home}/.docker"            "${configHome}/docker"
        move "${home}/.npmrc"             "${configHome}/npm/npmrc"

        move "${home}/.bash_history"      "${stateHome}/bash/history"
        move "${home}/.python_history"    "${stateHome}/python/history"
        move "${home}/.node_repl_history" "${stateHome}/node/repl_history"

        move "${home}/.bun"               "${dataHome}/bun"
        move "${home}/.pulumi"            "${dataHome}/pulumi"
        move "${home}/.keras"             "${dataHome}/keras"
        move "${home}/.codex"             "${configHome}/codex"
        move "${home}/.triton"            "${cacheHome}/triton"
        move "${home}/.nv"                "${cacheHome}/nv"
        move "${home}/.pulse-cookie"      "${stateHome}/pulse/cookie"
        move "${home}/.imageio"           "${dataHome}/imageio"
        # merge rather than move since claude pre-creates the dir
        if [ -e "${home}/.claude" ]; then
          $DRY_RUN_CMD mkdir -p "${configHome}/claude"
          if $DRY_RUN_CMD cp -an "${home}/.claude/." "${configHome}/claude/"; then
            $DRY_RUN_CMD rm -rf "${home}/.claude"
          fi
        fi
        if [ -e "${home}/.claude.json" ]; then
          $DRY_RUN_CMD mkdir -p "${configHome}/claude"
          if $DRY_RUN_CMD cp -an "${home}/.claude.json" "${configHome}/claude/.claude.json"; then
            $DRY_RUN_CMD rm -f "${home}/.claude.json"
          fi
        fi

        $DRY_RUN_CMD mkdir -p "${cacheHome}/terraform/plugins"
      '';
    };
}
