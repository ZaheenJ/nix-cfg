{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  # Old system generations accumulate in /nix until GC'd (the lanzaboote
  # configurationLimit only caps ESP boot entries, not disk). Weekly GC of
  # generations older than two weeks keeps rollback headroom without growth.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;

  # IP-geolocation timezone: sets tz via timedatectl at boot + hourly timer.
  # The module forces time.timeZone = null (imperative management).
  services.tzupdate.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";

  # Keyboard: niri's xkb config section is empty — it reads layout from
  # locale1, which NixOS populates from these options (localectl on Arch:
  # X11 us/altgr-intl, VC us-acentos).
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };
  console.keyMap = "us-acentos";

  networking.networkmanager.enable = true;
  services.resolved.enable = true;
  # Replaces ufw. Arch's only custom rules were KDE Connect ports for
  # Valent, which the user no longer uses — nothing extra to open.
  networking.firewall.enable = true;

  # Matches Arch zram-generator: zram-size = ram, zstd.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
  # Safety net against memory-exhaustion freezes. With zram-only (no disk swap)
  # the kernel OOM killer stays reluctant while it can still compress one more
  # page, so a runaway build can thrash the machine into a livelock instead of
  # being killed. earlyoom kills the biggest hog when free RAM crosses an
  # absolute threshold — the right tool for a runaway nix build, which it can
  # reach anywhere (unlike systemd-oomd, which only kills within managed slices,
  # so a build under nix-daemon.service/system.slice would slip past it).
  #
  # Caveat learned the hard way: earlyoom's kill logic is AND (mem AND swap both
  # under threshold) and it keys on MemAvailable. With vm.swappiness=180 the
  # kernel evicts anon pages to zram, keeping MemAvailable cosmetically healthy
  # while swap silently fills — so earlyoom is structurally blind to the "swap
  # exhausted, RAM looks fine" case (a slow leak filling zram over days).
  # freeSwapThreshold=100 does NOT catch that: because the logic is AND, maxing
  # it just makes the swap term always-true, leaving MemAvailable as the sole
  # trigger. So there is no safety net for a slow leak filling zram — the answer
  # is to kill the memory hog at the source. The 2026-07 freeze was driven mainly
  # by gaze's pam_gaze.so pinning ~2.8 GB mlock'd (unswappable) in greetd's
  # session-worker for the whole session — fixed by dropping greetd from
  # services.gaze.pamServices (hosts/home-g16/hardware.nix); a crashing
  # rog-control-center (removed in desktop-niri.nix) was a secondary factor.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 8; # SIGTERM at <8% free RAM; SIGKILL at half (~4%)
    freeSwapThreshold = 100; # AND-logic: leaves free RAM as the effective trigger
    enableNotifications = true;
  };
  # Tune VM for zram (kernel-docs/CachyOS guidance): swapping to compressed
  # RAM is nearly free, so swap aggressively (default 60 is tuned for disk)
  # and disable readahead clustering (pointless on zram, adds latency).
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    # Remaining cachyos-settings (70-cachyos-settings.conf) sysctls worth
    # carrying over. swappiness above is deliberately higher than their 100
    # (zram); these match upstream. Skipped: kernel.unprivileged_userns_clone
    # (Arch kernel patch, not a vanilla sysctl — NixOS enables userns by default).
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_bytes" = 268435456;
    "vm.dirty_background_bytes" = 67108864;
    "vm.dirty_writeback_centisecs" = 1500;
    "kernel.nmi_watchdog" = 0;
  };

  # sched-ext userspace scheduler on the vanilla kernel — CachyOS's default
  # desktop scheduler, most of its interactivity feel without their kernel.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # Realtime priority for audio (Arch used cachyos-settings' @audio rtprio
  # limits; rtkit is the NixOS-idiomatic equivalent).
  security.rtkit.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  services.fwupd.enable = true;
  services.fstrim.enable = true;

  # VIA keyboard (4d4b:3068) and RAWM mouse (1915:232a) hidraw access (from Arch udev rules).
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="4d4b", ATTRS{idProduct}=="3068", GROUP="users", MODE="0660"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1915", ATTRS{idProduct}=="232a", GROUP="users", MODE="0660"
  '';

  users.users.zaheenj = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    git
    man-pages
  ];
}
