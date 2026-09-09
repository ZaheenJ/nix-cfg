# Ghostty terminal emulator. Launches Nushell as the shell.
# Repeated Ghostty keys such as palette and keybind are represented as lists by
# Home Manager and rendered as duplicate config entries.
{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      command = "direct:nu";
      font-family = "Iosevka Nerd Font";
      font-size = 12;
      window-decoration = false;
      window-padding-x = 12;
      window-padding-y = 12;
      background-opacity = 0.75;
      background-blur = true;
      background-blur-radius = 32;
      cursor-style-blink = true;
      scrollback-limit = 3023;
      mouse-hide-while-typing = true;
      copy-on-select = false;
      confirm-close-surface = false;
      app-notifications = "no-clipboard-copy,no-config-reload";
      keybind = [
        "ctrl+shift+n=new_window"
        "ctrl+t=new_tab"
        "ctrl+plus=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+zero=reset_font_size"
        "shift+enter=text:\\n"
      ];
      unfocused-split-opacity = 0.7;
      unfocused-split-fill = "#44464f";
      gtk-titlebar = false;
      shell-integration = "detect";
      shell-integration-features = "cursor,sudo,title,no-cursor";
      gtk-single-instance = true;
      background = "000000";
      foreground = "ffffff";
      palette = [
        "0=#1a1a1a"
        "1=#dd5c40"
        "2=#6ed67f"
        "3=#d3db7b"
        "4=#d54bc8"
        "5=#d449c8"
        "6=#f000de"
        "7=#abb2bf"
        "8=#5c6370"
        "9=#e0765f"
        "10=#86e094"
        "11=#e1e897"
        "12=#ffbdf9"
        "13=#b357bc"
        "14=#b25e9f"
        "15=#ffffff"
      ];
    };
  };
}
