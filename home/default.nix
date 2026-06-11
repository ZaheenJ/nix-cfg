{ pkgs, ... }:
{
  # Common user environment for all hosts. Must stay distro-agnostic:
  # this is also used standalone on non-NixOS machines (school/work).
  home.username = "zaheenj";
  home.homeDirectory = "/home/zaheenj";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Skeleton only — full package set and dotfile ports land in Phase 3.
  home.packages = with pkgs; [
    fd
    ripgrep
  ];

  programs.fish.enable = true;
}
