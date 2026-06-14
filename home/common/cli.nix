# CLI tools: plain home.packages for everything from MAPPING.md CLI section,
# plus zoxide and carapace via their home-manager modules (with fish + nushell
# integrations). fd and ripgrep move here from the placeholder in default.nix.
{ pkgs, ... }:
{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  # tealdeer (tldr client); auto-refresh the page cache weekly.
  programs.tealdeer = {
    enable = true;
    settings.updates = {
      auto_update = true;
      auto_update_interval_hours = 168;
    };
  };

  home.packages = with pkgs; [
    # Search / filesystem
    fd
    ripgrep
    unzip

    # Disk usage
    dust
    duf
    ncdu

    # System monitoring
    bottom
    nvtopPackages.full
    powerstat

    # Code / project stats
    tokei

    # Timer / fun / utilities
    termdown
    figlet
    xkcdpass

    # Task management
    taskwarrior-tui

    # Dev tools
    man-pages
    mcp-nixos # used by Claude Code via repo .mcp.json
  ];
}
