# Shared user environment for ALL machines. Must stay distro-agnostic:
# also used via standalone home-manager on non-NixOS hosts.
{ pkgs, ... }:
{
  home.username = "zaheenj";
  home.homeDirectory = "/home/zaheenj";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Skeleton only — Phase 3 fills this out (see PLAN.md).
  home.packages = with pkgs; [
    fd
    ripgrep
  ];

  programs.fish.enable = true;
}
