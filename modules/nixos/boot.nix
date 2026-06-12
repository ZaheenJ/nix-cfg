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

  # BLS entry for Arch (CachyOS) on the shared ESP. lanzaboote ignores
  # boot.loader.systemd-boot.extraEntries, so ship the file via tmpfiles;
  # lzbt's ESP garbage collection only sweeps EFI/nixos and nixos-* in
  # EFI/Linux, so loader/entries/arch.conf survives rebuilds. Kernel and
  # cmdline taken verbatim from Arch's refind_linux.conf (2026-06-12); the
  # kernel is sbctl-signed on the Arch side, so it verifies under Secure Boot.
  systemd.tmpfiles.rules =
    let
      archEntry = pkgs.writeText "arch.conf" ''
        title CachyOS (Arch)
        sort-key z-arch
        linux /vmlinuz-linux-cachyos
        initrd /intel-ucode.img
        initrd /initramfs-linux-cachyos.img
        options quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3 zswap.enabled=0 nowatchdog vt.global_cursor_default=0 splash i915.enable_dpcd_backlight=3 rcutree.enable_rcu_lazy=1 rw rootflags=subvol=/@ root=UUID=b34a2639-b192-4add-a2ba-3deb931288ce
      '';
    in
    [ "C+ /boot/loader/entries/arch.conf - - - - ${archEntry}" ];

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

  # Quiet boot/shutdown: silence stage-1, kernel console, systemd unit
  # chatter (auto = only shown on errors/slowness, as on Arch), and the
  # getty greeting/help lines on VTs.
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 3;
  services.getty = {
    greetingLine = "";
    helpLine = "";
  };

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
