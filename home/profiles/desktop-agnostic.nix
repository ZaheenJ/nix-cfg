# Desktop-neutral GUI defaults; compositor shell and appearance stay separate.
{ pkgs, ... }:
{
  imports = [
    ../common/ghostty.nix
    ../common/xdg.nix
  ];

  home.packages = with pkgs; [
    noto-fonts-color-emoji
    nerd-fonts.iosevka
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts.emoji = [ "Noto Color Emoji" ];
  };

  programs.firefox.enable = true;

  xdg.mimeApps.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
  };
}
