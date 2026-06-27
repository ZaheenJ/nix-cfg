# fish: login shell. Sets PATH, defines helix-style keybindings, git
# abbreviations, and utility functions. (Session launch is greetd's job now,
# not loginShellInit — see modules/nixos/desktop-niri.nix.)
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
  };

  # Silence login(1)'s "Last login: ..." line on tty login (quiet boot).
  home.file.".hushlogin".text = "";

  # The helix-keybindings functions are large multi-function files (fish_helix_key_bindings
  # defines the main function plus many __fish_helix_* helpers in one file).
  # HM's programs.fish.functions only supports a single body per entry, so these
  # are shipped verbatim with xdg.configFile.
  xdg.configFile."fish/functions/fish_helix_key_bindings.fish".source =
    ./fish/fish_helix_key_bindings.fish;
  xdg.configFile."fish/functions/fish_helix_command.fish".source =
    ./fish/fish_helix_command.fish;
}
