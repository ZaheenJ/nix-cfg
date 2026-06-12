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

  home.packages = with pkgs; [
    # Search / filesystem
    fd
    ripgrep

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
    uv
    man-pages
    mcp-nixos # used by Claude Code via repo .mcp.json
  ];
}
