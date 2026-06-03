{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    fx-autoconfig = {
      url = "github:MrOtherGuy/fx-autoconfig";
      flake = false;
    };
    advanced-tab-groups = {
      url = "github:Vertex-Mods/Advanced-Tab-Groups";
      flake = false;
    };
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
