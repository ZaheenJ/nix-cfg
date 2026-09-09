{ pkgs, lib, ... }:
{
  imports = [ ../../modules/nixos/boot.nix ];

  # Secure Boot via lanzaboote, signing with the pre-existing sbctl keys
  # (copied from Arch's /var/lib/sbctl at install time). systemd-boot (the
  # lzbt-signed copy in EFI/systemd) is the sole boot manager: it auto-detects
  # Windows and gets a hand-shipped BLS entry for Arch below. lzbt never
  # touches NVRAM, and `bootctl install` must not be run here.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    # ESP is ~930 MB shared with Windows + Arch; keep generations few.
    configurationLimit = 4;
  };

  # lanzaboote's loader.conf reads this option; the default "keep" stays in
  # the firmware's low-res console mode and doesn't clear the BGRT logo,
  # making the menu render over a giant pixelated OEM logo.
  boot.loader.systemd-boot.consoleMode = "max";

  environment.systemPackages = [ pkgs.sbctl ];

  # Dual-boot BLS entry for Arch (CachyOS) on the shared ESP. lanzaboote
  # ignores boot.loader.systemd-boot.extraEntries, so ship this through
  # tmpfiles; its ESP garbage collection leaves this hand-maintained entry
  # alone.
  # Keep the foreign Arch command line verbatim: its performance parameters
  # are independent of NixOS's boot.kernelParams above.
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
}
