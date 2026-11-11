{
  pkgs,
  lib,
  homeDirectory,
  ...
}:
{
  name,
  repoUrl,
  configPath,
  submodules ? false,
}:

let
  dependencies = [ pkgs.git ];
  src = ''
    if [ ! -e "${homeDirectory}/${configPath}/.git" ]; then
        git clone ${
          if submodules then "--recurse-submodules " else ""
        }"${repoUrl}" "${homeDirectory}/${configPath}"
    elif cd "${homeDirectory}/${configPath}" && git rev-parse --is-inside-work-tree > /dev/null; then
        if status=$(git status --porcelain --untracked-files=normal --ignore-submodules=none); then
            if [ -n "$status" ]; then
                echo "${name}: local changes present; skipping update."
            elif git pull --ff-only --no-rebase; then
                echo "${name}: checkout is up to date."
                ${lib.optionalString submodules ''
                  if ! git submodule update --init --recursive; then
                      echo "${name}: submodule update failed; inspect the checkout before retrying." >&2
                  fi
                ''}
            else
                echo "${name}: could not fast-forward; leaving the checkout unchanged." >&2
            fi
        else
            echo "${name}: could not inspect the checkout; skipping update." >&2
        fi
    fi
  '';
  script = pkgs.writeShellScriptBin name src;
  build = pkgs.symlinkJoin {
    name = name;
    paths = [ script ] ++ dependencies;
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
  };
  data = "${build.outPath}/bin/${name}";
in
lib.hm.dag.entryAfter [ "writeBoundary" ] data
