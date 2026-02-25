{ ... }:
{
  flake.homeManagerModules.eza =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.eza ];

      home.file.".config/eza/theme.yml" = {
        source = pkgs.writeText "theme.yml" ''
          extensions:
              ncl: {icon: {glyph: 󰆧, style: {foreground: 38;2;224;195;252}}}
        '';
      };

      home.sessionVariables."EZA_CONFIG_DIR" = "$HOME/.config/eza";

      programs.bash = {
        bashrcExtra = ''
          alias ls='exa --icons -F -H --group-directories-first --git -1'
          alias ll='ls -alF'
          alias lt="exa --tree --level=2 --long --icons --git"
        '';
      };
    };
}
