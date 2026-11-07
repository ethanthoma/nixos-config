{ self, ... }:
{
  flake.homeManagerModules.cli =
    { ... }:
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
      };
    };
}
