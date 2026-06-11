# Desktop utilities for the niri/Wayland stack.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nwg-displays
    nwg-look
    playerctl
    wev
    brightnessctl
    pulsemixer
    wl-clipboard # niri screenshot bind: wl-paste | satty
  ];
}
