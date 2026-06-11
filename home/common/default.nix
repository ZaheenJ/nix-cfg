# Shared user environment for ALL machines. Must stay distro-agnostic:
# also used via standalone home-manager on non-NixOS hosts.
{ pkgs, ... }:
{
  imports = [
    ./fish.nix
    ./nushell.nix
  ];

  home.username = "zaheenj";
  home.homeDirectory = "/home/zaheenj";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Remaining CLI set moves to cli.nix in batch 1 completion (see PLAN.md).
  home.packages = with pkgs; [
    fd
    ripgrep
  ];
}
