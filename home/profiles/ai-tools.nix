# Mutable, user-writable AI CLI configuration with declarative MCP defaults.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.antigravity-cli = {
    enable = true;
    enableMcpIntegration = true;
  };

  programs.codex = {
    enable = true;
    enableMcpIntegration = false;
  };

  programs.mcp = {
    enable = true;
    servers.nixos.command = "mcp-nixos";
  };

  home.packages = [ pkgs.mcp-nixos ];

  home.activation.mergeCodexSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.codex"
    CONFIG_FILE="$HOME/.codex/config.toml"
    if [ -L "$CONFIG_FILE" ]; then
      cp --remove-destination "$(readlink -f "$CONFIG_FILE")" "$CONFIG_FILE"
    fi
    [ -f "$CONFIG_FILE" ] || touch "$CONFIG_FILE"

    DECLARED_SERVERS='${builtins.toJSON config.programs.mcp.servers}' \
      ${pkgs.python3.withPackages (ps: [ ps.tomlkit ])}/bin/python3 - << 'EOF'
    import json
    import os
    from pathlib import Path
    import tomlkit

    config_path = Path(os.environ["HOME"]) / ".codex" / "config.toml"
    content = config_path.read_text() if config_path.stat().st_size else ""
    try:
        doc = tomlkit.parse(content) if content.strip() else tomlkit.document()
    except Exception:
        doc = tomlkit.document()
    mcp_servers = doc.setdefault("mcp_servers", tomlkit.table())
    for name, srv in json.loads(os.environ.get("DECLARED_SERVERS", "{}")).items():
        server_tbl = mcp_servers.setdefault(name, tomlkit.table())
        for key in ("command", "args", "env"):
            if key in srv and srv[key]:
                server_tbl[key] = srv[key]
    config_path.write_text(tomlkit.dumps(doc))
    config_path.chmod(0o600)
    EOF
    chmod 600 "$CONFIG_FILE"
  '';

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
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$DEFAULTS") > "$SETTINGS_FILE.tmp" \
        && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    else
      echo "$DEFAULTS" | ${pkgs.jq}/bin/jq '.' > "$SETTINGS_FILE"
    fi
    chmod 600 "$SETTINGS_FILE"
  '';
}
