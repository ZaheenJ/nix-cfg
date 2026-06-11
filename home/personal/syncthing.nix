# Syncthing: home-manager user service (mirrors the Arch user service).
# Keys, device IDs, and folder configs are machine state — not vendored.
# Syncthing generates them on first run and persists them in its data dir.
{ ... }:
{
  services.syncthing.enable = true;
}
