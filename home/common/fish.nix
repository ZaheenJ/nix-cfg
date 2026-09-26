# fish: login shell. Sets PATH, keybindings, git abbreviations, and utility
# functions. (Session launch is greetd's job now,
# not loginShellInit — see modules/nixos/desktop-niri.nix.)
# Carapace and zoxide integrations live in cli.nix.
{ lib, pkgs, ... }:
{
  programs.fish = {
    enable = true;

    functions = {
      fish_greeting = {
        description = "Suppress greeting";
        body = "";
      };

      fgpl = {
        description = "git pull in every subdirectory";
        body = ''
          for dir in */
              $dir
              git pull
              ..
          end
        '';
      };

    };

    interactiveShellInit = ''
      set -g fish_key_bindings ${
        if pkgs.stdenv.hostPlatform.isDarwin then "fish_vi_key_bindings" else "fish_helix_key_bindings"
      }
      ${builtins.readFile ./fish/interactive.fish}
    '';
  };

  # Silence login(1)'s "Last login: ..." line on tty login (quiet boot).
  home.file.".hushlogin".text = "";

  # The helix-keybindings functions are large multi-function files (fish_helix_key_bindings
  # defines the main function plus many __fish_helix_* helpers in one file).
  # HM's programs.fish.functions only supports a single body per entry, so these
  # are shipped verbatim with xdg.configFile.
  xdg.configFile = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    "fish/functions/fish_helix_key_bindings.fish".source = ./fish/fish_helix_key_bindings.fish;
    "fish/functions/fish_helix_command.fish".source = ./fish/fish_helix_command.fish;
  };
}
