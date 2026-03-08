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
        overlays = [ (final: prev: { zen-browser = inputs.zen-browser.packages.${system}.default; }) ];
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
      };
    };
}
