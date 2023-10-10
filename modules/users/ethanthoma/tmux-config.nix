{ pkgs, homeDirectory, ... }:

let
    name = "tmux-config";
    dependencies = with pkgs; [ git ];
    src = ''
        git clone --recurse-submodules https://github.com/ethanthoma/tmux-config.git ${homeDirectory}/.config/tmux
    '';
    script = pkgs.writeShellScriptBin name src;
in pkgs.symlinkJoin {
    name = name;
    paths = [ script ] ++ dependencies;
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
}

#src = builtins.readFile ./clone-tmux-config;
#    script = (
#        pkgs.writeScriptBin name src
#    ).overrideAttrs(
#        old: {
#            buildCommand = "${old.buildCommand}\n patchShebangs $out";
#        }
#    );
