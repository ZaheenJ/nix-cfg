{
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  programs.niri.enable = true;

  # The greeter runs its own compositor; greetd launches the chosen Wayland
  # session after authentication.
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };
      keyboard = {
        layout = "us";
        variant = "altgr-intl";
      };
    };
  };
  # niri has no verbosity flag; it uses RUST_LOG (tracing). Left at its default
  # it logs at DEBUG (hundreds of "device changed" / screencasting lines). Cap
  # niri at warn to drop that flood while keeping warnings/errors (e.g. the
  # libinput "too slow" messages that flag real stalls). gaze sets its own
  # RUST_LOG per-service, so it's unaffected.
  environment.sessionVariables.RUST_LOG = "info,niri=warn";

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    bibata-cursors
  ];

  services.gnome.gnome-keyring.enable = true;
  # Authenticating at the greeter unlocks the login keyring (same password),
  # so git push / Secret Service / the gcr SSH agent stop prompting. Note: face
  # login (Gaze) doesn't type a password, so it won't unlock the keyring —
  # password login still does.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # nixpkgs now gates the setuid pkexec wrapper behind this (defaults off);
  # enable it so GUI polkit prompts (and `pkexec`) work — including Gaze face
  # auth on the polkit-1 stack (services.gaze.pam.defaultServices).
  security.polkit.enablePkexecWrapper = true;
}
