{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vesktop
    teams-for-linux
    slack
    zoom-us
  ];

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/discord" = "vesktop.desktop";
    "x-scheme-handler/slack" = "slack.desktop";
    "x-scheme-handler/msteams" = "teams-for-linux.desktop";
    "x-scheme-handler/zoommtg" = "Zoom.desktop";
    "x-scheme-handler/zoomus" = "Zoom.desktop";
    "x-scheme-handler/zoomphonecall" = "Zoom.desktop";
    "x-scheme-handler/tel" = "Zoom.desktop";
    "x-scheme-handler/callto" = "Zoom.desktop";
  };
}
