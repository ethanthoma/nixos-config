{ self, ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.ethanthoma =
    { lib, ... }:
    {
      imports = [
        self.homeManagerModules.apps
        self.homeManagerModules.atuin
        self.homeManagerModules.claude
        self.homeManagerModules.direnv
        self.homeManagerModules.eza
        self.homeManagerModules.fuzzel
        self.homeManagerModules.fzf
        self.homeManagerModules.ghostty
        self.homeManagerModules.git
        self.homeManagerModules.gpg
        self.homeManagerModules.keepassxc
        self.homeManagerModules.mako
        self.homeManagerModules.zen-mods
        self.homeManagerModules.neovim
        self.homeManagerModules.secretspec
        self.homeManagerModules.starship
        self.homeManagerModules.tmux
        self.homeManagerModules.waybar
        self.homeManagerModules.zoxide
        self.homeManagerModules.theme
        self.homeManagerModules.font
        self.homeManagerModules.xdg
      ];

      home = {
        username = "ethanthoma";
        homeDirectory = "/home/ethanthoma";
        stateVersion = "23.05";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        portalPackage = null;
        configType = "lua";
        extraConfig =
          builtins.replaceStrings [ "@background_color@" ] [ "0xff${lib.removePrefix "#" palette.base}" ]
            (builtins.readFile ../_files/hyprland.lua);
      };

      programs.home-manager.enable = true;
    };
}
