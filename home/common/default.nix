# Shared user environment for ALL machines. Must stay distro-agnostic:
# also used via standalone home-manager on non-NixOS hosts.
{ ... }:
{
  imports = [
    ./fish.nix
    ./nushell.nix
    ./starship.nix
    ./ghostty.nix
    ./helix.nix
    ./git.nix
    ./cli.nix
    ./yazi.nix
    ./xdg.nix
  ];

  home.username = "zaheenj";
  home.homeDirectory = "/home/zaheenj";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
