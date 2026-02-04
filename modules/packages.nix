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
        overlays = [ (final: prev: { thorium = prev.callPackage ./_packages/thorium.nix { }; }) ];
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
      };
    };
}
