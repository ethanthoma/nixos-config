{ inputs, self, ... }:

let
  system = "x86_64-linux";
  username = "ethanthoma";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  flake.homeConfigurations."${username}@${system}" =
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      lib = inputs.nixpkgs.lib // inputs.home-manager.lib;
      modules = [
        self.homeManagerModules.ethanthoma
        {
          home.packages = [
            inputs.rose-pine-hyprcursor.packages.${system}.default
          ];
        }
      ];
    };
}
