# niri: vendor config.kdl (user-edited) via xdg.configFile.
# noctalia.kdl and monitor.kdl are deliberately NOT managed: they are
# app-written outputs (noctalia's niri color template; nwg-displays) and
# read-only symlinks block those writers. Seeded once at migration.
# The niri *package* comes from programs.niri in modules/nixos/desktop-niri.nix.
# Executables referenced by config.kdl (lead must confirm all are packaged):
#   spawn-at-startup: noctalia, vicinae
#   binds/spawns: ghostty, vicinae, noctalia, systemctl, asusctl,
#                 firefox, zathura, vesktop, cmus (via ghostty -e),
#                 wl-paste, satty (Mod+Shift+S screenshot annotation)
{ ... }:
{
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
}
