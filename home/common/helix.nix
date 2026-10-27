# Uses gj1118's Helix fork for code folding and UI customizations.
{
  lib,
  pkgs,
  helixInput,
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
    package = helixInput.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
        "color-modes" = true;
        bufferline = {
          "render-mode" = "multiple";
          separator = "";
        };
        breadcrumb = {
          enable = true;
          path = "full";
          "max-depth" = 8;
          "max-name-length" = 32;
        };
        statusline = {
          left = [
            "mode"
            "file-name"
            "file-modification-indicator"
          ];
          center = [ ];
          right = [
            "diagnostics"
            "selections"
            "position"
          ];
        };
        "popup-border" = "all";
        "end-of-line-diagnostics" = "hint";
        "rounded-corners" = true;
        cmdline = {
          style = "popup";
          "use-full-height" = true;
        };
        "gradient-borders" = {
          enable = true;
          thickness = 1;
          direction = "horizontal";
          "start-color" = "#FF0080";
          "end-color" = "#00FFFF";
          "animation-speed" = 2;
        };
        notifications.shadow.enable = false;
        "inline-blame" = {
          show = "cursor-line";
          format = "{author} • {time-ago} • {title}";
          "auto-fetch" = false;
        };
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
        lsp = {
          "display-inlay-hints" = true;
          "signature-help-position" = "below";
        };
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
