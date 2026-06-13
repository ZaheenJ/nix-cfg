# Personal-laptop-only user environment (browsers, gaming, media, chat, ...).
{ ... }:
{
  imports = [
    ./niri.nix
    ./noctalia.nix
    ./vicinae.nix
    ./satty.nix
    ./desktop-tools.nix
    ./theming.nix
    ./fonts.nix
    ./apps.nix
    ./media.nix
    ./power.nix
    ./syncthing.nix
  ];
}
