# Desktop utilities for the niri/Wayland stack.
{ pkgs, ... }:
{
  programs.satty.enable = true;
  home.packages = with pkgs; [
    nwg-displays
    nwg-look
    playerctl
    wev
    brightnessctl
    pulsemixer
    wl-clipboard
  ];
}
