{ inputs, ... }:

let
  hostname = "atlas";
  username = "ethoma";

  # atlas is a headless server that tracks newer packages than the desktops (ROCm, kernel), so it pins its own
  # nixpkgs and builds everything against it. Its modules live in ./_atlas and see these under the usual names.
  atlas_inputs = {
    tether = inputs.tether;
    claude-code = inputs.atlas-claude-code;
    codex-cli = inputs.atlas-codex-cli;
  };
in
{
  flake.nixosConfigurations.${hostname} = inputs.atlas-nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit username;
      inputs = atlas_inputs;
    };
    modules = [
      { networking.hostName = hostname; }
      ./_atlas/configuration.nix
      inputs.sops-nix.nixosModules.sops
      inputs.atlas-home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import ./_atlas/home.nix;
        home-manager.extraSpecialArgs = { inherit username; };
      }
    ];
  };
}
