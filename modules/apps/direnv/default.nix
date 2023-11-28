{ home, ... }:

{
    programs = {
        direnv = {
            enable = true;
            enableBashIntegration = true; # see note on other shells below
                nix-direnv.enable = true;
        };

        bash.enable = true; # see note on other shells below
    };

    programs.bash = {
        bashrcExtra = ''
            eval "$(direnv hook bash)"
        '';
    };
}

