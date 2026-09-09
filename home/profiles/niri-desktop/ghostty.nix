# Visual Ghostty settings for the niri desktop. Functional settings are shared.
{ ... }:
{
  programs.ghostty.settings = {
    font-family = "Iosevka Nerd Font";
    font-size = 12;
    window-decoration = false;
    window-padding-x = 12;
    window-padding-y = 12;
    background-opacity = 0.75;
    background-blur = true;
    background-blur-radius = 32;
    cursor-style-blink = true;
    unfocused-split-opacity = 0.7;
    unfocused-split-fill = "#44464f";
    gtk-titlebar = false;
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
}
