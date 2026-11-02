# Mutable, user-writable AI CLI configuration with declarative MCP defaults.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  merger = ./cloud-ai-tools/merge_settings.py;
in
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
    run ${python}/bin/python3 ${merger} codex "$HOME/.codex/config.toml" \
      ${lib.escapeShellArg (builtins.toJSON config.programs.mcp.servers)}
  '';

  home.activation.mergeAntigravitySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${python}/bin/python3 ${merger} antigravity "$HOME/.gemini/antigravity-cli/settings.json" \
      ${lib.escapeShellArg (
        builtins.toJSON {
          colorScheme = "tokyo night";
          altScreenMode = "always";
          editorMode = "vim";
          vimInsertFirst = true;
          notifications = true;
          enableTerminalSandbox = true;
          toolPermission = "proceed-in-sandbox";
        }
      )}
  '';
}
