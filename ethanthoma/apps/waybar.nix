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
          tooltip = false;
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "{:%Y-%m-%d | %H:%M}";
        };
        "pulseaudio" = {
          tooltip = false;
          format = "{icon} {volume}%  {format_source}";
          format-bluetooth = "{icon} {volume}%  {format_source}";
          format-bluetooth-muted = "{icon} 󰝟 0%  {format_source}";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            portable = "";
            default = [
              ""
              ""
              ""
            ];
          };
          format-muted = "󰝟 0%  {format_source}";
          format-source-muted = "0%";
          on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
          on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        };
        "network" = {
          format-wifi = "{icon} {essid}";
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
          format-plugged = " {capacity}%";
          states = {
            critical = 15;
            warning = 30;
          };
        };
      };
    };
    style = ''
      /*
      * Variant: Rosé Pine
      * Maintainer: DankChoir
      */

      @define-color base            #191724;
      @define-color surface         #1f1d2e;
      @define-color overlay         #26233a;

      @define-color muted           #6e6a86;
      @define-color subtle          #908caa;
      @define-color text            #e0def4;

      @define-color love            #eb6f92;
      @define-color gold            #f6c177;
      @define-color rose            #ebbcba;
      @define-color pine            #31748f;
      @define-color foam            #9ccfd8;
      @define-color iris            #c4a7e7;

      @define-color highlightLow    #21202e;
      @define-color highlightMed    #403d52;
      @define-color highlightHigh   #524f67;

      window#waybar {
          background: @base;
          border-bottom: 2px solid @gold;
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
}
