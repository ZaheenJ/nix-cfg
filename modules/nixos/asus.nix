{ pkgs, ... }:
{
  services.power-profiles-daemon.enable = true;

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # "sufficient" = face OR password, matching Arch; the NixOS default
  # "required" would demand both factors.
  services.howdy = {
    enable = true;
    control = "sufficient";
  };
  services.linux-enable-ir-emitter.enable = true;

  # TODO (research, see PLAN.md): intel-lpmd has no NixOS module; the Arch
  # AC/battery udev scripts (inventory/etc/{ac,bat}.fish) depend on
  # intel_lpmd_control + brightnessctl + niri msg — port in a later phase.
}
