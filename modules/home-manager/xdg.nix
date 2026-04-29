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

        # Node / npm
        NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
        npm_config_cache = "${cacheHome}/npm";
        npm_config_prefix = "${dataHome}/npm";
        NODE_REPL_HISTORY = "${stateHome}/node/repl_history";

        # Python
        PYTHONSTARTUP = "${configHome}/python/startup.py";

        # GnuPG
        GNUPGHOME = "${dataHome}/gnupg";

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
      };

      programs.bash.historyFile = "${stateHome}/bash/history";

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
      '';
    };
}
