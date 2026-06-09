{ ... }:
{
  flake.nixosModules.common =
    { pkgs, ... }:
    {
      nix = {
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 7d";
        };
        optimise.automatic = true;
        settings = {
          auto-optimise-store = true;
          use-xdg-base-directories = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
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
        pkgs.zen-browser
        pkgs.bottom
        pkgs.openconnect_openssl
      ];
    };
}
