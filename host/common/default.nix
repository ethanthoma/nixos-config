{ pkgs, ... }:

{
  environment.systemPackages =
    let
      thorium = pkgs.callPackage ./thorium.nix { };
    in
    [ thorium ];
}
