{ pkgs, inputs, ... }:
let
  serein = inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.serein;
in
{
  home.packages = with pkgs; [
    serein
    teams-for-linux
    slack
    zoom-us
  ];

  # Discord URLs open/focus Serein; navigating to their target is not yet supported.
  xdg.desktopEntries."cz.viceverse.serein" = {
    name = "Serein";
    comment = "Experimental unofficial native Discord client";
    exec = "${serein}/bin/serein %u";
    icon = "serein";
    terminal = false;
    categories = [
      "Network"
      "InstantMessaging"
    ];
    mimeType = [ "x-scheme-handler/discord" ];
    settings.StartupWMClass = "cz.viceverse.serein";
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/discord" = "cz.viceverse.serein.desktop";
    "x-scheme-handler/slack" = "slack.desktop";
    "x-scheme-handler/msteams" = "teams-for-linux.desktop";
    "x-scheme-handler/zoommtg" = "Zoom.desktop";
    "x-scheme-handler/zoomus" = "Zoom.desktop";
    "x-scheme-handler/zoomphonecall" = "Zoom.desktop";
    "x-scheme-handler/tel" = "Zoom.desktop";
    "x-scheme-handler/callto" = "Zoom.desktop";
  };
}
