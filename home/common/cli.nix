# CLI tools: plain home.packages for everything from MAPPING.md CLI section,
# plus zoxide and carapace via their home-manager modules (with fish + nushell
# integrations). fd and ripgrep move here from the placeholder in default.nix.
{ pkgs, lib, ... }:
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "ews" = {
        hostname = "linux.ews.illinois.edu";
        user = "zaheenj2";
      };
    };
  };

  # LLMs
  programs.antigravity-cli = {
    enable = true;
    enableMcpIntegration = true;
    # settings left empty so HM doesn't manage settings.json as a static symlink,
    # which conflicts when the CLI writes trustedWorkspaces / state at runtime.
  };

  # Deep-merge declarative defaults into mutable settings.json on switch
  home.activation.mergeAntigravitySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.gemini/antigravity-cli"
    SETTINGS_FILE="$HOME/.gemini/antigravity-cli/settings.json"
    DEFAULTS='{
      "colorScheme": "tokyo night",
      "altScreenMode": "always",
      "editorMode": "vim",
      "vimInsertFirst": true,
      "notifications": true
    }'

    if [ -s "$SETTINGS_FILE" ] && ${pkgs.jq}/bin/jq -e . "$SETTINGS_FILE" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$DEFAULTS") > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    else
      echo "$DEFAULTS" | ${pkgs.jq}/bin/jq '.' > "$SETTINGS_FILE"
    fi
    chmod 600 "$SETTINGS_FILE"
    rm -f "$HOME/.gemini/antigravity-cli/settings.json.hm-bak"
  '';

  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    extraConfig = ''
      # Include machine-local sync credentials (WingTask)
      include ~/.config/task/sync.rc
    '';
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
