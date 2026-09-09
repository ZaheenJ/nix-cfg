# GUI apps and their URL/file associations. Application profiles and settings
# remain mutable runtime state rather than read-only Home Manager files.
{ pkgs, ... }:
{
  programs.firefox.enable = true;

  programs.chromium.enable = true;

  home.packages = with pkgs; [
    # Chat / social
    vesktop

    # Gaming
    prismlauncher

    # Work communication
    teams-for-linux
    slack
    zoom-us

    # Privacy browser
    tor-browser

    # Mobile development
    android-tools

    # Shazam client
    songrec
  ];

  xdg.mimeApps.defaultApplications = {
    # Default web browser: Firefox
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";

    # Chat / social
    "x-scheme-handler/discord" = "vesktop.desktop";

    # Work communication
    "x-scheme-handler/slack" = "slack.desktop";
    "x-scheme-handler/msteams" = "teams-for-linux.desktop";
    "x-scheme-handler/zoommtg" = "Zoom.desktop";
    "x-scheme-handler/zoomus" = "Zoom.desktop";
    "x-scheme-handler/zoomphonecall" = "Zoom.desktop";
    "x-scheme-handler/tel" = "Zoom.desktop";
    "x-scheme-handler/callto" = "Zoom.desktop";

    # Gaming (modpack links)
    "x-scheme-handler/curseforge" = "org.prismlauncher.PrismLauncher.desktop";
    "x-scheme-handler/prismlauncher" = "org.prismlauncher.PrismLauncher.desktop";
    "application/x-modrinth-modpack+zip" = "org.prismlauncher.PrismLauncher.desktop";
  };
}
