{ inputs, ... }:
{
  flake.nixosModules.common =
    { pkgs, ... }:
    let
      zen_packages = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system};
      zen_unwrapped = zen_packages.zen-browser-unwrapped;
      zen-browser = import ../_lib/zen-with-autoconfig.nix {
        inherit (pkgs) runCommand;
        zen = zen_packages.default.override {
          zen-browser-unwrapped =
            if zen_unwrapped.version == "1.23.3b" then
              zen_unwrapped.override {
                hash =
                  {
                    x86_64-linux = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
                    aarch64-linux = "sha256-EQDLPoVyVO26gzopPrUAEN5moWZGXt/NzIU23ecy36c=";
                  }
                  .${pkgs.stdenv.hostPlatform.system};
              }
            else
              zen_unwrapped;
        };
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
            "https://codex-cli.cachix.org"
          ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
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

      services.speechd.enable = false;

      documentation.nixos.enable = false;

      environment.defaultPackages = [ ];

      environment.variables.QT_BEARER_POLL_TIMEOUT = "-1";

      environment.systemPackages = [
        zen-browser
        pkgs.bottom
        pkgs.tokei
        pkgs.openconnect_openssl
      ];
    };
}
