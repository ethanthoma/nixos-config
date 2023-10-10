{ pkgs, homeDirectory, ... }:

let
    name = "nvim-config";
    dependencies = with pkgs; [ git ];
    src = ''
        git clone https://github.com/ethanthoma/neovim.git ${homeDirectory}/.config/nvim
    '';
    script = pkgs.writeShellScriptBin name src;
in pkgs.symlinkJoin {
    name = name;
    paths = [ script ] ++ dependencies;
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
}

