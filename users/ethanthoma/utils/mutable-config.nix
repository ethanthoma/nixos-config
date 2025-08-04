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
    if [ ! -d "${homeDirectory}/${configPath}" ]; then
        git clone ${
          if submodules then "--recurse-submodules " else ""
        }${repoUrl} ${homeDirectory}/${configPath}
    elif cd ${homeDirectory}/${configPath} && git rev-parse --is-inside-work-tree > /dev/null; then
        if [[ $(git ls-files --modified --other --exclude-standard --directory --no-empty-directory -o) ]] ||
           [[ $(! git diff-index --quiet HEAD --) ]]; then
            echo -e "\033[31mThere are uncommitted changes in your ${name}, please commit them.\033[0m"
        else
            echo "Up to date"
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
  data = ''${build.outPath}/bin/${name}'';
in
lib.hm.dag.entryAfter [ "writeBoundary" ] data
