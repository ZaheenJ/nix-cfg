{ pkgs, ... }:
{
  # Generic quiet boot policy. Machine-specific kernel parameters live with the
  # host hardware; performance parameters live in the host performance module.
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
    "vt.global_cursor_default=0"
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
    # Quiet-boot cosmetics only; normal tty login remains available.
    extraArgs = [
      "--nonewline"
      "--noissue"
      "--noclear"
    ];
  };

  # Make boot menu hidden by default
  boot.loader.timeout = 0;

  # Preserve firmware-provided branding with the BGRT-aware NixOS theme rather
  # than replacing it with a plain spinner.
  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [ pkgs.nixos-bgrt-plymouth ];
  };
}
