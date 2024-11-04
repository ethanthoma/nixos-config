{ ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      window_padding_width = 5;
      background_opacity = "0.75";
      confirm_os_window_close = 0;
    };
    themeFile = "rose-pine";
    keybindings = {
      "ctrl+c" = "copy_and_clear_or_interrupt";
      "ctrl+v" = "paste_from_clipboard";
    };
    extraConfig = "font_family JetBrains Mono";
  };
}
