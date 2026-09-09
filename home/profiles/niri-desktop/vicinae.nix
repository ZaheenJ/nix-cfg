# Vicinae keeps its settings mutable because the application writes runtime state.
{ ... }:
{
  programs.vicinae.enable = true;

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/vicinae" = "vicinae-url-handler.desktop";
    "x-scheme-handler/raycast" = "vicinae-url-handler.desktop";
    "x-scheme-handler/com.raycast" = "vicinae-url-handler.desktop";
  };
}
