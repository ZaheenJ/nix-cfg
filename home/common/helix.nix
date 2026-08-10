# helix: uses flake input helix (master) for unreleased SystemVerilog support.
# Language servers included: lua-language-server (verified), tinymist (verified).
# slang-server (SystemVerilog LSP) is DEFERRED — commented out in languages.
{ pkgs, inputs, ... }:
{
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    extraPackages = with pkgs; [
      tinymist
      nil # nix LSP (helix uses it for .nix by default)
      nixfmt # nix formatter
      clang-tools # C/CPP LSP
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
        "C-z" = ":sh zathura --fork $(basename %{buffer_name} typ)pdf";
        tab = "move_parent_node_end";
        "S-tab" = "move_parent_node_start";
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
      # slang-server is DEFERRED: SystemVerilog LSP not yet packaged.
      # "language-server".slang-server.command = "slang-server";
      language = [
        {
          name = "systemverilog";
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
