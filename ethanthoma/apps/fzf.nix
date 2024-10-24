{ pkgs, ... }:

{
  home.packages = with pkgs; [ fzf ];

  programs = {
    fzf.enable = true;

    bash.bashrcExtra = ''
      export FZF_DEFAULT_OPTS="
          --height 50% --layout=reverse --border
          --color=fg:#908caa,bg:#191724,hl:#ebbcba
          --color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba
          --color=border:#403d52,header:#31748f,gutter:#191724
          --color=spinner:#f6c177,info:#9ccfd8
          --color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

      if command -v fzf-share >/dev/null; then
          source "$(fzf-share)/key-bindings.bash"
          source "$(fzf-share)/completion.bash"
      fi
    '';
  };
}
