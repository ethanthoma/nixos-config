{ self, ... }:
{
  flake.homeManagerModules.cli =
    { pkgs, ... }:
    {
      imports = [
        self.homeManagerModules.agent-memory
        self.homeManagerModules.atuin
        self.homeManagerModules.direnv
        self.homeManagerModules.fzf
        self.homeManagerModules.git-common
        self.homeManagerModules.neovim
        self.homeManagerModules.starship
        self.homeManagerModules.tmux
        self.homeManagerModules.zoxide
      ];

      programs.bash = {
        enable = true;
        enableCompletion = true;
        initExtra = ''
          # Readline bindings apply only at the shell prompt, not inside pi.
          _paste_clipboard() {
            local clipboard
            clipboard=$(${pkgs.coreutils}/bin/timeout 3 ${pkgs.wl-clipboard}/bin/wl-paste --no-newline --type text && printf '\001') || return
            clipboard=''${clipboard%$'\001'}
            READLINE_LINE="''${READLINE_LINE:0:READLINE_POINT}$clipboard''${READLINE_LINE:READLINE_POINT}"
            READLINE_POINT=$((READLINE_POINT + ''${#clipboard}))
          }
          # Otherwise Readline restores the terminal's literal-next binding at each prompt.
          bind 'set bind-tty-special-chars off'
          bind -m emacs-standard -x '"\C-v":_paste_clipboard'
          bind -m vi-insert -x '"\C-v":_paste_clipboard'
        '';
      };
    };
}
