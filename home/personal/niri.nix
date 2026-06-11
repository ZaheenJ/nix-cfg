# niri: vendor config.kdl, noctalia.kdl, and monitor.kdl via xdg.configFile.
# The niri *package* comes from programs.niri in modules/nixos/desktop-niri.nix.
# Executables referenced by config.kdl (lead must confirm all are packaged):
#   spawn-at-startup: rog-control-center (asusctl), noctalia, vicinae
#   binds/spawns: ghostty, vicinae, noctalia, systemctl, asusctl,
#                 firefox, zathura, vesktop, cmus (via ghostty -e),
#                 wl-paste, satty (Mod+Shift+S screenshot annotation)
{ ... }:
{
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
  xdg.configFile."niri/noctalia.kdl".source = ./niri/noctalia.kdl;
  xdg.configFile."niri/monitor.kdl".source = ./niri/monitor.kdl;
}
