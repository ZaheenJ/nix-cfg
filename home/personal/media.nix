# Media: mpv (with hwdec), cmus (package only — no rc file exists), vimiv
# (package only — no config files exist), zathura (ported from zathurarc).
# zathura is dependency-installed on Arch but actively used by niri binds.
{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";
    };
  };

  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      font = "Iosevka NF 12";
      default-bg = "rgba(0,0,0,0.75)";
      default-fg = "rgba(80,0,255,1.0)";
      recolor-lightcolor = "rgba(0,0,0,0)";
      recolor = true;
      statusbar-bg = "rgba(0,0,0,0.2)";
      statusbar-fg = "rgba(80,0,255,1.0)";
      inputbar-bg = "rgba(0,0,0,0.2)";
      inputbar-fg = "rgba(80,0,255,1.0)";
      completion-bg = "rgba(0,0,0,0.0)";
      completion-fg = "rgba(80,0,255,1.0)";
      completion-group-bg = "rgba(0,0,0,0.2)";
      completion-highlight-fg = "rgba(0,0,0,1.0)";
      completion-highlight-bg = "rgba(80,0,255,1.0)";
    };
  };

  home.packages = with pkgs; [
    cmus
    vimiv-qt
    yt-dlp
    tickrs
  ];
}
