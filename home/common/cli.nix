# CLI tools: plain home.packages for everything from MAPPING.md CLI section,
# plus zoxide and carapace via their home-manager modules (with fish + nushell
# integrations). fd and ripgrep move here from the placeholder in default.nix.
{
  pkgs,
  lib,
  config,
  ...
}:
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

  programs.codex = {
    enable = true;
    # settings and enableMcpIntegration left empty/false so HM doesn't manage
    # config.toml as a static symlink, which conflicts when Codex writes
    # trusted projects / TUI state at runtime.
    enableMcpIntegration = false;
  };

  # Deep-merge declarative MCP config into mutable ~/.codex/config.toml on switch
  home.activation.mergeCodexSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.codex"
        CONFIG_FILE="$HOME/.codex/config.toml"
        BAK_FILE="$HOME/.codex/config.toml.hm-bak"

        # If currently a symlink (from HM), convert to a real writable file
        if [ -L "$CONFIG_FILE" ]; then
          cp --remove-destination "$(readlink -f "$CONFIG_FILE")" "$CONFIG_FILE"
          chmod 600 "$CONFIG_FILE"
        elif [ ! -f "$CONFIG_FILE" ] && [ -f "$BAK_FILE" ]; then
          cp "$BAK_FILE" "$CONFIG_FILE"
          chmod 600 "$CONFIG_FILE"
        fi

        [ -f "$CONFIG_FILE" ] || touch "$CONFIG_FILE"

        DECLARED_SERVERS='${
          builtins.toJSON (if config.programs.mcp.enable then config.programs.mcp.servers else { })
        }' \
          ${pkgs.python3.withPackages (ps: [ ps.tomlkit ])}/bin/python3 - << 'EOF'
    import json
    import os
    from pathlib import Path
    import tomlkit

    config_path = Path(os.environ["HOME"]) / ".codex" / "config.toml"
    bak_path = Path(os.environ["HOME"]) / ".codex" / "config.toml.hm-bak"

    content = ""
    if config_path.is_file() and config_path.stat().st_size > 0:
        content = config_path.read_text()
    elif bak_path.is_file() and bak_path.stat().st_size > 0:
        content = bak_path.read_text()

    try:
        doc = tomlkit.parse(content) if content.strip() else tomlkit.document()
    except Exception:
        doc = tomlkit.document()

    mcp_servers = doc.setdefault("mcp_servers", tomlkit.table())
    declared_servers = json.loads(os.environ.get("DECLARED_SERVERS", "{}"))

    for name, srv in declared_servers.items():
        server_tbl = mcp_servers.setdefault(name, tomlkit.table())
        if "command" in srv:
            server_tbl["command"] = srv["command"]
        if "args" in srv and srv["args"]:
            server_tbl["args"] = srv["args"]
        if "env" in srv and srv["env"]:
            server_tbl["env"] = srv["env"]

    config_path.write_text(tomlkit.dumps(doc))
    config_path.chmod(0o600)
    EOF

        rm -f "$BAK_FILE"
  '';

  # Deep-merge declarative defaults into mutable settings.json on switch
  home.activation.mergeAntigravitySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.gemini/antigravity-cli"
    SETTINGS_FILE="$HOME/.gemini/antigravity-cli/settings.json"
    DEFAULTS='{
      "colorScheme": "tokyo night",
      "altScreenMode": "always",
      "editorMode": "vim",
      "vimInsertFirst": true,
      "notifications": true,
      "enableTerminalSandbox": true,
      "toolPermission": "proceed-in-sandbox"
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
