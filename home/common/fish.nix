# fish: login shell only. Launches niri-session on tty1, sets PATH, defines
# helix-style keybindings, git abbreviations, and utility functions.
# Carapace and zoxide integrations live in cli.nix.
{ ... }:
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

      power-draw = {
        description = "Show current battery power draw in watts";
        body = ''
          echo (math (cat /sys/class/power_supply/BAT1/current_now) \* \
          (cat /sys/class/power_supply/BAT1/voltage_now) \* \
          0.000000000001)" W"
        '';
      };
    };

    shellInit = ''
      fish_add_path ~/.local/bin ~/.cargo/bin ~/.local/share/cargo/bin /opt/cuda/bin
    '';

    interactiveShellInit = builtins.readFile ./fish/interactive.fish;

    # Launch niri-session on tty1 when fish is the login shell
    loginShellInit = ''
      if test -z "$WAYLAND_DISPLAY" && test -z "$DISPLAY" && test "$XDG_VTNR" = 1
          exec niri-session -l &>~/.niri.log
      end
    '';
  };

  # The helix-keybindings functions are large multi-function files (fish_helix_key_bindings
  # defines the main function plus many __fish_helix_* helpers in one file).
  # HM's programs.fish.functions only supports a single body per entry, so these
  # are shipped verbatim with xdg.configFile.
  xdg.configFile."fish/functions/fish_helix_key_bindings.fish".source =
    ./fish/fish_helix_key_bindings.fish;
  xdg.configFile."fish/functions/fish_helix_command.fish".source =
    ./fish/fish_helix_command.fish;
}
