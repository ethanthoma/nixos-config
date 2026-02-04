{ self, ... }:
{
  flake.homeManagerModules.ethanthoma =
    { ... }:
    {
      imports = [
        self.homeManagerModules.apps
        self.homeManagerModules.claude
        self.homeManagerModules.direnv
        self.homeManagerModules.eza
        self.homeManagerModules.fuzzel
        self.homeManagerModules.fzf
        self.homeManagerModules.ghostty
        self.homeManagerModules.git
        self.homeManagerModules.mako
        self.homeManagerModules.neovim
        self.homeManagerModules.starship
        self.homeManagerModules.tmux
        self.homeManagerModules.waybar
        self.homeManagerModules.zoxide
        self.homeManagerModules.theme
        self.homeManagerModules.font
      ];

      home = {
        username = "ethanthoma";
        homeDirectory = "/home/ethanthoma";
        stateVersion = "23.05";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        extraConfig = builtins.readFile ../_files/hyprland.conf;
      };

      programs.home-manager.enable = true;
    };
}
