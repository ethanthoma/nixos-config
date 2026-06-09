{ ... }:
let
  palette = import ../_lib/palette.nix;
in
{
  flake.homeManagerModules.waybar =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.font-awesome
        pkgs.pulseaudio
      ];

      programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings = {
          default = {
            layer = "top";
            position = "top";
            modules-left = [
              "clock"
            ];
            modules-center = [ ];
            modules-right = [
              "pulseaudio"
              "network"
              "battery"
            ];
            "clock" = {
              on-click = "";
              tooltip = false;
              format = "{:%d %b %R}";
            };
            "pulseaudio" = {
              tooltip = false;
              format = "{icon}  {volume}%  {format_source}";
              format-bluetooth = "{icon} {volume}%  {format_source}";
              format-bluetooth-muted = "{icon} 󰝟 0%  {format_source}";
              format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                portable = "";
                default = [
                  " "
                  " "
                  " "
                ];
              };
              format-muted = "󰝟 0%  {format_source}";
              format-source-muted = "0%";
              on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
              on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            };
            "network" = {
              format-wifi = "{icon}  {essid}";
              tooltip = false;
              format-icons = [
                "󰤯"
                "󰤟"
                "󰤢"
                "󰤥"
                "󰤨"
              ];
              format-ethernet = "󰈀";
              format-linked = "{ifname} 󰈀";
              format-disconnected = "󰤫";
            };
            "battery" = {
              tooltip = false;
              format = "{icon} {capacity}%";
              format-alt = "{icon} {time}";
              format-charging = "󰂄 {capacity}%";
              format-icons = [
                "󰁺"
                "󰁻"
                "󰁼"
                "󰁽"
                "󰁾"
                "󰁿"
                "󰂀"
                "󰂁"
                "󰂂"
                "󰁹"
              ];
              format-plugged = " {capacity}%";
              states = {
                critical = 15;
                warning = 30;
              };
            };
          };
        };
        style = ''
          @define-color base            ${palette.base};
          @define-color surface         ${palette.surface};
          @define-color overlay         ${palette.overlay};

          @define-color muted           ${palette.muted};
          @define-color subtle          ${palette.subtle};
          @define-color text            ${palette.text};

          @define-color love            ${palette.love};
          @define-color gold            ${palette.gold};
          @define-color rose            ${palette.rose};
          @define-color pine            ${palette.pine};
          @define-color foam            ${palette.foam};
          @define-color iris            ${palette.iris};

          @define-color highlightLow    ${palette.highlightLow};
          @define-color highlightMed    ${palette.highlightMed};
          @define-color highlightHigh   ${palette.highlightHigh};

          window#waybar {
              background: @base;
              color: @text;
              font-family: Monaspace Neon;
          }

          window#waybar > * {
              padding-left: 20px;
              padding-right: 20px;
          }

          #clock { margin: 0; }

          *.module {
              margin-left: 20px;
              padding: 5px;
          }
        '';
      };
    };
}
