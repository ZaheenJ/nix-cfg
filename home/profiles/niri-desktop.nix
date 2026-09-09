# Desktop profile for the niri compositor and its shell.
{ ... }:
{
  imports = [
    ./niri-desktop/ghostty.nix
    ./niri-desktop/niri.nix
    ./niri-desktop/noctalia.nix
    ./niri-desktop/desktop-tools.nix
    ./niri-desktop/theming.nix
    ./niri-desktop/vicinae.nix
  ];
}
