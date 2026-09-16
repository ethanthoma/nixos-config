# bash completion for secretspec 0.19 (https://secretspec.dev)

_secretspec_subcommands() {
  case $1 in
  '') echo 'init add set get delete run export check schema config import cache audit help' ;;
  config) echo 'global provider help' ;;
  'config global') echo 'init show provider help' ;;
  'config global provider') echo 'add remove list help' ;;
  'config provider') echo 'login help' ;;
  cache) echo 'clear help' ;;
  esac
}

# secretspec.toml selected by -f/--file, then $SECRETSPEC_FILE, then the
# nearest one walking up from $PWD. Reads `words`/`cword` from the caller.
_secretspec_manifest() {
  local index directory
  for ((index = 1; index < cword; index++)); do
    case ${words[index]} in
    -f | --file)
      printf '%s\n' "${words[index + 1]}"
      return
      ;;
    esac
  done
  if [[ -n ${SECRETSPEC_FILE:-} ]]; then
    printf '%s\n' "$SECRETSPEC_FILE"
    return
  fi
  directory=$PWD
  for ((index = 0; index < 32; index++)); do
    if [[ -f $directory/secretspec.toml ]]; then
      printf '%s\n' "$directory/secretspec.toml"
      return
    fi
    [[ $directory == / ]] && return
    directory=${directory%/*}
    directory=${directory:-/}
  done
}

# Secret names are env var names, so uppercase-only filtering separates them
# from the lowercase attribute keys of a `[profiles.<profile>.<SECRET>]` table.
_secretspec_secrets() {
  local manifest line section='' name count=0
  manifest=$(_secretspec_manifest)
  [[ -r $manifest ]] || return
  while IFS= read -r line && ((++count < 2000)); do
    line=${line%%#*}
    line=${line#"${line%%[![:space:]]*}"}
    if [[ $line == '['*']'* ]]; then
      section=${line:1}
      section=${section%%]*}
      name=${section##*.}
      [[ $section == profiles.*.* && $name =~ ^[A-Z_][A-Z0-9_]*$ ]] && printf '%s\n' "$name"
      continue
    fi
    [[ $section == profiles.* ]] || continue
    name=${line%%[[:space:]=]*}
    [[ $name =~ ^[A-Z_][A-Z0-9_]*$ ]] && printf '%s\n' "$name"
  done <"$manifest" | sort -u
}

# Table names under a `[<prefix>...]` section, in both the section form
# (`[providers.work]`) and the inline form (`[providers]` + `work = "..."`).
_secretspec_tables() {
  local file=$1 prefix=$2 line section='' rest count=0
  [[ -r $file ]] || return
  while IFS= read -r line && ((++count < 2000)); do
    line=${line%%#*}
    line=${line#"${line%%[![:space:]]*}"}
    if [[ $line == '['*']'* ]]; then
      section=${line:1}
      section=${section%%]*}
      if [[ $section == "$prefix"?* ]]; then
        rest=${section#"$prefix"}
        printf '%s\n' "${rest%%.*}"
      fi
      continue
    fi
    [[ $section. == "$prefix" && $line == *=* ]] && printf '%s\n' "${line%%[[:space:]=]*}"
  done <"$file" | sort -u
}

_secretspec_aliases() {
  _secretspec_tables "${XDG_CONFIG_HOME:-$HOME/.config}/secretspec/config.toml" 'providers.'
  _secretspec_tables "$(_secretspec_manifest)" 'providers.'
}

_secretspec() {
  local cur prev words cword
  _init_completion -n : || return

  local providers='1password age akv awsps awssm bw bws dashlane dotenv env file gcsm gopass
    infisical kdbx keeper keyring lastpass null onepassword op openbao pass passbolt protonpass
    scaleway sops systemd-credential vault'

  # Walk the words once: known subcommands extend the command path, the rest
  # are positional arguments. Option values are skipped so they never count.
  local command='' arguments=0 first_argument=0 index word subcommands
  for ((index = 1; index < cword; index++)); do
    word=${words[index]}
    case $word in
    -f | --file | -p | --provider | -P | --profile | -S | --scope | --reason | --format | \
      --from | --project | --action | -o | --output | -d | --description | --credential | --tail)
      ((index++))
      continue
      ;;
    -n)
      [[ $command == audit ]] && ((index++))
      continue
      ;;
    -*) continue ;;
    esac
    subcommands=$(_secretspec_subcommands "$command")
    if [[ " $subcommands " == *" $word "* ]]; then
      command=${command:+$command }$word
    else
      ((arguments == 0)) && first_argument=$index
      ((arguments++))
    fi
  done

  # Everything from the first positional of `run` on belongs to the child command.
  if [[ $command == run ]] && ((arguments > 0)); then
    _command_offset "$first_argument"
    return
  fi

  case $prev in
  -f | --file | -o | --output)
    _filedir
    return
    ;;
  -p | --provider)
    COMPREPLY=($(compgen -W "$providers $(_secretspec_aliases)" -- "$cur"))
    return
    ;;
  -P | --profile)
    COMPREPLY=($(compgen -W "$(_secretspec_tables "$(_secretspec_manifest)" 'profiles.')" -- "$cur"))
    return
    ;;
  -S | --scope)
    COMPREPLY=($(compgen -W "$(_secretspec_tables "$(_secretspec_manifest)" 'scopes.')" -- "$cur"))
    return
    ;;
  --format)
    COMPREPLY=($(compgen -W 'shell dotenv json gha' -- "$cur"))
    return
    ;;
  --action)
    COMPREPLY=($(compgen -W 'get set delete check run import export cache_clear' -- "$cur"))
    return
    ;;
  --from)
    local uris='' provider
    for provider in $providers; do
      uris+=" $provider://"
    done
    COMPREPLY=($(compgen -W "$uris" -- "$cur"))
    compopt -o nospace
    __ltrim_colon_completions "$cur"
    return
    ;;
  --reason | --project | -d | --description | --credential | --tail)
    return
    ;;
  -n)
    [[ $command == audit ]] && return
    ;;
  esac

  if [[ $command == run && $cur != -* ]]; then
    _command_offset "$cword"
    return
  fi

  local options
  case $command in
  '') options='-f --file --reason -h --help -V --version' ;;
  init) options='-f --file --from --project --reason -P --profile -h --help' ;;
  add) options='-d --description -f --file -P --profile --reason -h --help' ;;
  set | get) options='-f --file -p --provider -P --profile --reason -h --help' ;;
  delete) options='--all -y --yes -f --file -p --provider -P --profile --reason -h --help' ;;
  run) options='-f --file -p --provider -P --profile -S --scope --reason -h --help' ;;
  export) options='-f --file -p --provider -P --profile -S --scope --format --reason -h --help' ;;
  check) options='-f --file -p --provider -P --profile -S --scope -n --no-prompt --json --explain --reason -h --help' ;;
  schema) options='-f --file -P --profile -o --output --reason -h --help' ;;
  import) options='--delete-source -f --file --reason -h --help' ;;
  audit) options='--project --action -n --tail --json -f --file --reason -h --help' ;;
  'cache clear') options='-f --file -P --profile --reason -h --help' ;;
  'config global init') options='-p --provider -P --profile -f --file --reason -h --help' ;;
  'config global provider add') options='--credential -f --file --reason -h --help' ;;
  *) options='-f --file --reason -h --help' ;;
  esac

  # `help <TAB>` lists the sibling commands it can explain.
  local candidates parent=$command
  [[ $parent == help ]] && parent=''
  [[ $parent == *' help' ]] && parent=${parent% help}
  candidates=$(_secretspec_subcommands "$parent")
  case $command in
  get | set | add) ((arguments == 0)) && candidates+=" $(_secretspec_secrets)" ;;
  delete | 'cache clear') candidates+=" $(_secretspec_secrets)" ;;
  import) ((arguments == 0)) && candidates+=" $providers $(_secretspec_aliases)" ;;
  'config provider login' | 'config global provider remove')
    ((arguments == 0)) && candidates+=" $(_secretspec_aliases)"
    ;;
  esac

  [[ $cur == -* || -z ${candidates//[[:space:]]/} ]] && candidates=$options
  COMPREPLY=($(compgen -W "$candidates" -- "$cur"))
}

complete -F _secretspec secretspec
