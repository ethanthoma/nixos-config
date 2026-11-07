{ ... }:
{
  flake.homeManagerModules.git =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.git-lfs
      ];

      programs.git = {
        settings = {
          safe.directory = [ "*" ];
          credential = {
            "https://github.com".helper = [
              ""
              "!${pkgs.gh}/bin/gh auth git-credential"
            ];
            "https://gist.github.com".helper = [
              ""
              "!${pkgs.gh}/bin/gh auth git-credential"
            ];
          };
        };
      };
    };
}
