# Tracks Helix master for unreleased SystemVerilog support.
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  openPdf = pkgs.writeShellScript "helix-open-pdf" ''
    set -eu
    [ "$#" -ge 1 ]
    pdf="''${1%.*}.pdf"
    ${pkgs.xdg-utils}/bin/xdg-open "$pdf" >/dev/null 2>&1 &
  '';
in
{
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    extraPackages = with pkgs; [
      tinymist # typst LSP
      nil # nix LSP
      nixfmt
      clang-tools # C/CPP LSP
      jdt-language-server # java
      slang-server # SystemVerilog LSP
    ];

    settings = {
      theme = "tokyonight_transparent";
      editor = {
        "line-number" = "relative";
        bufferline = "multiple";
        "popup-border" = "all";
        "end-of-line-diagnostics" = "hint";
        "cursor-shape" = {
          insert = "bar";
          select = "underline";
        };
        "indent-guides".render = true;
        whitespace = {
          render.newline = "all";
          characters.newline = "↴";
        };
        "inline-diagnostics"."cursor-line" = "warning";
        lsp."display-inlay-hints" = true;
      };
      keys.normal = {
        tab = "move_parent_node_end";
        "S-tab" = "move_parent_node_start";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        "C-z" = ":sh ${openPdf} \"%{file_path_absolute}\"";
      };
      keys.insert."S-tab" = "move_parent_node_start";
      keys.select = {
        tab = "extend_parent_node_end";
        "S-tab" = "extend_parent_node_start";
        ";" = [
          "collapse_selection"
          "normal_mode"
        ];
        x = "extend_line";
      };
    };

    languages = {
      "language-server".tinymist.config = {
        exportPdf = "onType";
      };
      "language-server".slang-server.command = "slang-server";
      language = [
        {
          name = "systemverilog";
          "language-servers" = [ "slang-server" ];
          "auto-pairs" = {
            "(" = ")";
            "{" = "}";
            "[" = "]";
            "\"" = "\"";
          };
        }
      ];
    };
  };

  # Custom themes are not managed by the HM helix module; vendor verbatim.
  xdg.configFile."helix/themes/tokyonight_transparent.toml".source =
    ./helix/themes/tokyonight_transparent.toml;
  xdg.configFile."helix/themes/catppuccin_mocha_transparent.toml".source =
    ./helix/themes/catppuccin_mocha_transparent.toml;
}
