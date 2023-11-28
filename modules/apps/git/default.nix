{ home, ... }:

{
    programs.git = {
        enable = true;
        aliases = {
            ci = "commit";
            co = "checkout";
            s = "status";
        };
        extraConfig = {
            push = {
                autoSetupRemote = "true";
            }; 
        };
    };
}

