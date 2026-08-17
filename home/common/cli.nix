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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableNushellIntegration = true;
    enableFishIntegration = true;
  };

  # LLMs
  programs.antigravity-cli = {
    enable = true;

    settings = {
      colorScheme = "tokyo night";
      altScreenMode = "always";
      editorMode = "vim";
      vimInsertFirst = true;
      notifications = true;
    };

    enableMcpIntegration = true;
  };

  programs.mcp = {
    enable = true;

    servers = {
      # Package installed below
      nixos = {
        command = "mcp-nixos";
      };
    };
  };

  home.packages = with pkgs; [
    # Search / filesystem
    fd
    ripgrep
    fzf # fuzzy finder; also backs zoxide's `z -i` and yazi's fzf/zoxide jumps
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
    libqalculate # `qalc` CLI calculator

    # Task management
    taskwarrior-tui

    # Dev tools that don't depend on FHS
    man-pages
    mcp-nixos # used by LLMs
  ];
}
