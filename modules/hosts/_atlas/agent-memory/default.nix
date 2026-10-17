{
  pkgs ? import <nixpkgs> { },
}:
pkgs.stdenv.mkDerivation {
  pname = "agent-memory";
  version = "0.1.0";
  src = pkgs.lib.cleanSource ./.;
  nativeBuildInputs = [
    pkgs.rustc
    pkgs.makeWrapper
    pkgs.git
  ];
  buildPhase = ''
    rustc --edition=2024 -D warnings -O main.rs -o agent-memory
  '';
  doCheck = true;
  checkPhase = ''
    MEMORY_BINARY="$PWD/agent-memory" rustc --edition=2024 -D warnings --test tests.rs -o memory-tests
    ./memory-tests
    rustc --edition=2024 -D warnings --test search.rs -o search-tests
    ./search-tests
    rustc --edition=2024 -D warnings --test hook.rs -o hook-tests
    ./hook-tests
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp agent-memory $out/bin/
    wrapProgram $out/bin/agent-memory --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git ]}
  '';
}
