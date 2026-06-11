{ pkgs, ... }:
{
  programs.niri.enable = true;

  # No display manager: niri-session is launched from fish on tty login,
  # same as the Arch setup (greetd was installed there but inactive).

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
