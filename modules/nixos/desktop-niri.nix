{ pkgs, inputs, config, ... }:
{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  programs.niri.enable = true;

  # Login via greetd + noctalia-greeter (password login, replacing the old
  # getty autologin). The greeter runs its own wlroots compositor and offers
  # user / password / session / colorscheme; greetd then launches the chosen
  # Wayland session as the authenticated user.
  programs.noctalia-greeter = {
    enable = true;
    package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };
      keyboard.layout = "us";
    };
  };
  # User that RUNS the greeter (unprivileged); the greetd module creates it.
  services.greetd.settings.default_session.user = "greeter";

  # The greeter scans /run/current-system/sw/share/wayland-sessions for
  # session entries; nixpkgs' programs.niri doesn't link niri.desktop there,
  # so add the niri package to systemPackages to expose niri as a choice.
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    config.programs.niri.package
  ];

  services.gnome.gnome-keyring.enable = true;
  # Authenticating at the greeter unlocks the login keyring (same password),
  # so git push / Secret Service / the gcr SSH agent stop prompting. Howdy
  # (services.howdy, "sufficient") auto-attaches to this PAM service too, so
  # face auth works at the greeter, falling through to password on failure.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Howdy breaks GUI polkit auth: in-session it can't open the IR camera, and
  # pam_howdy fails the PAM *conversation* instead of falling through, so the
  # polkit agent reports "invalid password" instantly. Drop face auth from
  # polkit prompts only; keep it for login / sudo / swaylock / the greeter.
  security.pam.services.polkit-1.howdy.enable = false;
}
