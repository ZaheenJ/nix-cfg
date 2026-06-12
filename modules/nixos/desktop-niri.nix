{ pkgs, ... }:
{
  programs.niri.enable = true;

  # No display manager: tty1 autologs zaheenj (Arch had a getty@tty1
  # drop-in: agetty --autologin), then fish's loginShellInit execs
  # niri-session on vt1. NixOS's option applies to all vts, not just tty1 —
  # acceptable difference on a single-user laptop.
  services.getty.autologinUser = "zaheenj";

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
