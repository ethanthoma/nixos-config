# Run a shell-init generator at build time and capture its output into the
# store, so the shell sources static text instead of forking the tool on every
# startup. Safe only for generators whose output is deterministic.
{ runCommand }:
name: command:
runCommand "${name}-init.bash" { } ''
  export HOME="$NIX_BUILD_TOP"
  ${command} > "$out"
''
