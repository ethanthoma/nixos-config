{ inputs, self, ... }:
{
  flake.nixosModules.user =
    { pkgs, ... }:
    let
      username = "ethanthoma";
    in
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      nixpkgs.config.allowUnfree = true;

      users.users.${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        extraGroups = [
          "networkmanager"
          "wheel"
          "audio"
        ];
      };

      services.getty.autologinUser = username;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = {
          imports = [ self.homeManagerModules.ethanthoma ];
          home.packages = [
            inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
          ];
        };
      };
    };
}
