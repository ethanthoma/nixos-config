{
  inputs,
  ...
}:

{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            zen-browser = import ./_lib/zen-with-autoconfig.nix {
              inherit (prev) runCommand;
              zen = inputs.zen-browser.packages.${system}.default;
              fx-autoconfig = inputs.fx-autoconfig;
            };
          })
        ];
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
      };
    };
}
