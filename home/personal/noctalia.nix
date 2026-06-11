# noctalia: shell bar from the flake input (v5 API, TOML config).
# NOTE: the flake input ships noctalia v5 whose config format is TOML
# (config.toml), incompatible with the v4 JSON (settings.json) currently on
# disk. The module is enabled here so the package is installed and the user
# service can be wired up; runtime settings are managed interactively via the
# noctalia Settings UI on first launch. Do NOT vendor the v4 settings.json.
#
# The pam/ subdirectory in ~/.config/noctalia/ contains a PAM override for
# lock-screen auth (password.conf). NixOS manages PAM via its own module system;
# do not vendor this file. Revisit when wiring up the lock screen on NixOS.
{ inputs, pkgs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    # package is set to inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    # by the homeModules.default wrapper — no need to re-declare it here.
  };
}
