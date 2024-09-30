{ pkgs, ... }:

{
  home.packages = with pkgs; [ fzf ];

  programs.bash = {
    bashrcExtra = ''
      export FZF_DEFAULT_OPTS="
          --height 50% --layout=reverse --border
      "

      if command -v fzf-share >/dev/null; then
          source "$(fzf-share)/key-bindings.bash"
          source "$(fzf-share)/completion.bash"
      fi
    '';
  };
}
