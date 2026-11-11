{ self, ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.ethanthoma =
    { lib, ... }:
    {
      imports = [
        ./_agent-cache
        ./_agent-skills
        self.homeManagerModules.cli
        self.homeManagerModules.apps
        self.homeManagerModules.codex
        self.homeManagerModules.eza
        self.homeManagerModules.fizzy
        self.homeManagerModules.fuzzel
        self.homeManagerModules.ghostty
        self.homeManagerModules.git
        self.homeManagerModules.gpg
        self.homeManagerModules.hypridle
        self.homeManagerModules.keepassxc
        self.homeManagerModules.mako
        self.homeManagerModules.zen-mods
        self.homeManagerModules.pi
        self.homeManagerModules.secretspec
        self.homeManagerModules.waybar
        self.homeManagerModules.workspace-indicator
        self.homeManagerModules.yubikey-touch-detector
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
