# `noctalia.kdl` is generated at runtime and included by the managed Niri
# config. Keeping it mutable avoids blocking Noctalia with a read-only symlink.
{ ... }:
{
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
}
