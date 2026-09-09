{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tickrs
    xkcdpass
    figlet
    termdown
  ];
}
