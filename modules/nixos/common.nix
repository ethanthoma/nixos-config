{ inputs, ... }:
{
  flake.nixosModules.common =
    { pkgs, ... }:
    let
      zen-browser = import ../_lib/zen-with-autoconfig.nix {
        inherit (pkgs) runCommand;
        zen = inputs.zen-browser.packages.${pkgs.system}.default;
        inherit (inputs) fx-autoconfig;
      };
    in
    {
      nix = {
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 7d";
        };
        optimise.automatic = true;
        settings = {
          use-xdg-base-directories = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];

          extra-substituters = [
            "https://nix-community.cachix.org"
            "https://hyprland.cachix.org"
          ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          ];

          max-jobs = "auto";
          cores = 0;
          keep-derivations = true;
          keep-outputs = true;
        };
        extraOptions = ''
          min-free = ${toString (1024 * 1024 * 1024)}
          max-free = ${toString (1024 * 1024 * 1024)}
        '';
      };

      environment.variables.QT_BEARER_POLL_TIMEOUT = "-1";

      environment.systemPackages = [
        zen-browser
        pkgs.bottom
        pkgs.openconnect_openssl
      ];
    };
}
