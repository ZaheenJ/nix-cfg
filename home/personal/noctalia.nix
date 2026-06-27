# noctalia: shell bar from the flake input (tracking HEAD).
#
# Two-layer config (current noctalia design):
#   - programs.noctalia.settings -> declarative BASE written to
#     ~/.config/noctalia/config.toml (read-only, from ./noctalia/config.toml
#     — a real TOML file, edit it there).
#   - ~/.local/state/noctalia/settings.toml -> runtime overrides written by
#     the Settings UI. Fold changes worth keeping back into the base file.
#
# The pam/ dir from Arch's config was a lock-screen PAM override; NixOS
# manages PAM declaratively — revisit when wiring the lock screen.
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    settings = ./noctalia/config.toml;
  };
}
