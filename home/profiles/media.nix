# Non-music media players, viewers, and associations.
{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    config.hwdec = "auto-safe";
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

  programs.yazi.extraPackages = [ pkgs.ffmpeg ];

  home.packages = with pkgs; [ vimiv-qt ];

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
    "application/x-pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
    "application/x-bzpdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
    "application/x-gzpdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
    "video/mp4" = "mpv.desktop";
    "video/mkv" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
    "video/avi" = "mpv.desktop";
    "audio/mpeg" = "mpv.desktop";
    "audio/flac" = "mpv.desktop";
    "audio/ogg" = "mpv.desktop";
    "audio/opus" = "mpv.desktop";
    "audio/wav" = "mpv.desktop";
    "audio/x-wav" = "mpv.desktop";
    "audio/aac" = "mpv.desktop";
    "audio/m4a" = "mpv.desktop";
    "audio/x-m4a" = "mpv.desktop";
    "image/jpeg" = "vimiv.desktop";
    "image/png" = "vimiv.desktop";
    "image/gif" = "vimiv.desktop";
    "image/webp" = "vimiv.desktop";
    "image/bmp" = "vimiv.desktop";
    "image/tiff" = "vimiv.desktop";
    "image/svg+xml" = "vimiv.desktop";
    "image/avif" = "vimiv.desktop";
  };
}
