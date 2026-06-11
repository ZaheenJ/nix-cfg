# noctalia: shell bar from the flake input, pinned to the exact rev the user
# runs on Arch (v5.0.0, reads ~/.config/noctalia/settings.json).
#
# settings.json is deliberately NOT managed by Nix: noctalia writes it at
# runtime (Settings UI hot-saves), and a home-manager file would be a
# read-only store symlink. It is mutable user state — copied to the new
# /home during the Phase 4 install (see PLAN.md), like browser profiles.
#
# The pam/ subdirectory in ~/.config/noctalia/ contains a PAM override for
# lock-screen auth (password.conf). NixOS manages PAM via its own module
# system; do not vendor this file. Revisit when wiring up the lock screen.
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  # The homeModules wrapper sets the package from the flake input; niri's
  # spawn-at-startup launches it (no systemd user service, matching Arch).
  programs.noctalia.enable = true;
}
