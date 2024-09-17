{ ... }:

{
  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    bash = {
      bashrcExtra = ''
        eval "$(direnv hook bash)"
      '';
    };
  };
}
