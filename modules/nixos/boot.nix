{ lib, pkgs, ... }:
{
  # Secure Boot via lanzaboote, signing with the pre-existing sbctl keys
  # (copied from Arch's /var/lib/sbctl at install time). systemd-boot (the
  # lzbt-signed copy in EFI/systemd) is the sole boot manager: it auto-detects
  # Windows (EFI/Microsoft, same ESP) and gets a hand-shipped BLS entry for
  # Arch below. Its "Linux Boot Manager" NVRAM entry was created once with
  # efibootmgr — lzbt never touches NVRAM, and `bootctl install` must NOT be
  # run (it would overwrite the signed systemd-boot binary with an unsigned one).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  # Ignored under boot.loader.external (lanzaboote), kept for documentation:
  # nothing on the NixOS side may add/reorder EFI variables automatically.
  boot.loader.efi.canTouchEfiVariables = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    # ESP is ~930 MB shared with Windows + Arch; keep generations few.
    configurationLimit = 4;
  };

  # Vanilla kernel per user preference (no CachyOS variants).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Ported from Arch cmdline; zswap off because zram is used.
  # systemd.show_status=auto and rd.udev.log_level=3 silence systemd/udev
  # console chatter at boot AND shutdown (consoleLogLevel only covers kernel
  # messages, not these). Machine-specific params (backlight quirk) live in
  # the host's hardware.nix.
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
    "nowatchdog"
    "zswap.enabled=0"
    "vt.global_cursor_default=0"
    "rcutree.enable_rcu_lazy=1"
  ];
  boot.kernel.sysctl."kernel.printk" = "3 3 3 3";

  # Quiet boot/shutdown: silence stage-1, kernel console, systemd unit
  # chatter (auto = only shown on errors/slowness, as on Arch), and the
  # getty greeting/help lines on VTs.
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 3;
  services.getty = {
    greetingLine = "";
    helpLine = "";
    # Match Arch's getty@tty1 drop-in (inventory/etc/getty-tty1-autologin.conf);
    # --autologin comes from services.getty.autologinUser in desktop-niri.nix.
    extraArgs = [
      "--skip-login"
      "--nonewline"
      "--noissue"
      "--noclear"
    ];
  };

  # Make boot menu hidden by default
  boot.loader.timeout = 0;
  # lanzaboote's loader.conf reads this option; the default "keep" stays in
  # the firmware's low-res console mode and doesn't clear the BGRT logo,
  # making the menu render over a giant pixelated OEM logo.
  boot.loader.systemd-boot.consoleMode = "max";

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
