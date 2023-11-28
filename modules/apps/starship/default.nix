{ home, ... }:

{
    programs.starship = {
        enable = true;
    };

    programs.bash = {
        bashrcExtra = ''
            eval "$(starship init bash)"
        '';
    };
}

