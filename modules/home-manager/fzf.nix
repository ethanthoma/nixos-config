{ ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.fzf =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fzf ];

      programs = {
        fzf.enable = true;

        bash.bashrcExtra = ''
          export FZF_DEFAULT_OPTS="
              --height 50% --layout=reverse --border
              --color=fg:${palette.subtle},bg:${palette.base},hl:${palette.rose}
              --color=fg+:${palette.text},bg+:${palette.overlay},hl+:${palette.rose}
              --color=border:${palette.highlightMed},header:${palette.pine},gutter:${palette.base}
              --color=spinner:${palette.gold},info:${palette.foam}
              --color=pointer:${palette.iris},marker:${palette.love},prompt:${palette.subtle}"

          if command -v fzf-share >/dev/null; then
              source "$(fzf-share)/key-bindings.bash"
              source "$(fzf-share)/completion.bash"
          fi
        '';
      };
    };
}
