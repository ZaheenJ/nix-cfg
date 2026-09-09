# Vicinae's `settings.json` remains app-written runtime state rather than a
# read-only Home Manager file.
{ ... }:
{
  programs.vicinae.enable = true;

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/vicinae" = "vicinae-url-handler.desktop";
    "x-scheme-handler/raycast" = "vicinae-url-handler.desktop";
    "x-scheme-handler/com.raycast" = "vicinae-url-handler.desktop";
  };
}
