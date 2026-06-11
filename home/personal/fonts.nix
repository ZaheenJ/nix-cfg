# Fonts: Noto Color Emoji as default emoji font (replicates Arch's
# noto-color-emoji-fontconfig package), plus Iosevka Nerd Font for UI/terminal.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    noto-fonts-color-emoji
    nerd-fonts.iosevka
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts.emoji = [ "Noto Color Emoji" ];
  };
}
