{ inputs, ... }:
{
  flake.nixosModules.codex-web =
    { pkgs, ... }:
    let
      username = "ethanthoma";
      home = "/home/${username}";
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      imports = [ inputs.codex-web.nixosModules.session-host ];

      services.codex-web-host = {
        enable = true;
        user = username;
        # The plain CLI, not the codex-atlas-wrapper home-manager puts on PATH:
        # the app-server needs no provider keys to read and run sessions.
        codex.package = inputs.codex-cli.packages.${system}.default;
        codex.home = "${home}/.config/codex";
        claude.enable = false;
      };
    };
}
