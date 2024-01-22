{ home, ... }:

{
    programs = {
        direnv = {
            enable = true;
            enableBashIntegration = true;
            nix-direnv.enable = true;
        };

        bash.enable = true;
    };

    programs.bash = {
        bashrcExtra = ''
            eval "$(direnv hook bash)"
        '';
    };
}

