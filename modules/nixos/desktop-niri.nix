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

  # niri has no verbosity flag; it uses RUST_LOG (tracing). Left at its default
  # it logs at DEBUG (hundreds of "device changed" / screencasting lines). Cap
  # niri at warn to drop that flood while keeping warnings/errors (e.g. the
  # libinput "too slow" messages that flag real stalls). gaze sets its own
  # RUST_LOG per-service, so it's unaffected.
  environment.sessionVariables.RUST_LOG = "info,niri=warn";

  # The greeter scans /run/current-system/sw/share/wayland-sessions for
  # session entries; nixpkgs' programs.niri doesn't link niri.desktop there,
  # so add the niri package to systemPackages to expose niri as a choice.
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    config.programs.niri.package
  ];

  services.gnome.gnome-keyring.enable = true;
  # Authenticating at the greeter unlocks the login keyring (same password),
  # so git push / Secret Service / the gcr SSH agent stop prompting. Note: face
  # login (gaze) doesn't type a password, so it won't unlock the keyring —
  # password login still does.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # nixpkgs now gates the setuid pkexec wrapper behind this (defaults off);
  # enable it so GUI polkit prompts (and `pkexec`) work — including gaze face
  # auth on the polkit-1 stack (services.gaze.pamServices).
  security.polkit.enablePkexecWrapper = true;
}
