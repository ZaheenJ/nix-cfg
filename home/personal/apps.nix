# GUI apps: browsers, chat, launchers, dev tools, media tagging.
# No profile/session/settings data vendored — these apps write their own
# config at runtime (vesktop settings.json included); it's all copied to the
# new /home in Phase 4 instead (see PLAN.md).
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

    # Privacy browser
    tor-browser

    # AI / dev tools
    code-cursor
    claude-code

    # Mobile development
    android-tools

    # Cloud tools
    google-cloud-sdk

    # Shazam client
    songrec
  ];
}
