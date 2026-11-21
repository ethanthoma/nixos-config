{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt;
      checks.formatting = pkgs.runCommand "nixfmt-check" { } ''
        find ${../flake.nix} ${./.} -name '*.nix' -exec ${pkgs.nixfmt}/bin/nixfmt --check {} +
        touch "$out"
      '';
      checks.google-cloud = pkgs.runCommand "google-cloud-check" { } ''
        ${pkgs.nixfmt}/bin/nixfmt --check ${./nixos/google-cloud.nix}
        ${pkgs.statix}/bin/statix check ${./nixos/google-cloud.nix}
        touch "$out"
      '';
      devshells.default.packages = [
        pkgs.ast-grep
        pkgs.nixfmt
        pkgs.statix
      ];
    };
}
