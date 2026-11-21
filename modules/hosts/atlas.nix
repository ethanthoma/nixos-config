{ inputs, self, ... }:

let
  hostname = "atlas";
  username = "ethanthoma";

  # atlas is a headless server that tracks newer packages than the desktops (ROCm, kernel), so it pins its own
  # nixpkgs and builds everything against it. Its modules live in ./_atlas and see these under the usual names.
  atlas_inputs = {
    runboard = inputs.runboard;
    codex-cli = inputs.atlas-codex-cli;
    pi = inputs.pi;
  };
in
{
  flake.nixosConfigurations.${hostname} = inputs.atlas-nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit username;
      inputs = atlas_inputs;
    };
    modules = [
      {
        networking.hostName = hostname;
        services.bootvine.enable = true;
      }
      inputs.bootvine.nixosModules.default
      inputs.holyfurries.nixosModules.atlas
      ./_atlas/configuration.nix
      self.nixosModules.google-cloud
      inputs.atlas-home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username}.imports = [
          self.homeManagerModules.cli
          self.homeManagerModules.pi-settings
          ./_atlas/home.nix
        ];
        home-manager.extraSpecialArgs = { inherit username inputs; };
      }
    ];
  };
}
