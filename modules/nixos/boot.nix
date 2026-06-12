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

  # Match the CachyOS look the user wants: firmware ASUS ROG logo stays
  # centered (BGRT) with NixOS branding, instead of plain spinner which
  # replaced the ROG image (first-boot feedback 2026-06-11).
  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [ pkgs.nixos-bgrt-plymouth ];
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
