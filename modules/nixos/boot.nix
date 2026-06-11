{ lib, pkgs, ... }:
{
  # Secure Boot via lanzaboote, signing with the pre-existing sbctl keys
  # (copied from Arch's /var/lib/sbctl at install time). rEFInd remains the
  # primary boot manager and auto-detects the signed UKIs on the shared ESP.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  # rEFInd owns BootOrder; don't let NixOS add/reorder EFI variables.
  boot.loader.efi.canTouchEfiVariables = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    # ESP is ~930 MB shared with Windows + Arch; keep generations few.
    configurationLimit = 4;
  };

  # Vanilla kernel per user preference (no CachyOS variants).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Ported from Arch cmdline; i915.enable_dpcd_backlight=3 is a G16 panel
  # backlight quirk, zswap off because zram is used.
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "nowatchdog"
    "zswap.enabled=0"
    "vt.global_cursor_default=0"
    "i915.enable_dpcd_backlight=3"
  ];
  boot.kernel.sysctl."kernel.printk" = "3 3 3 3";

  # User wants: black background, distro logo toward the bottom (like the
  # CachyOS theme), NOT the firmware/ASUS logo centered (bgrt theme).
  # "spinner" = black bg + spinner; verify placement on first real boot and
  # adjust theme/logo then — cosmetic, not boot-critical.
  boot.plymouth = {
    enable = true;
    theme = "spinner";
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
