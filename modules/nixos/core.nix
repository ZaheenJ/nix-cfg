{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
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

  # VIA keyboard (4d4b:3068) and 1915:232a hidraw access (from Arch udev rules).
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="4d4b", ATTRS{idProduct}=="3068", GROUP="users", MODE="0660"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1915", ATTRS{idProduct}=="232a", GROUP="users", MODE="0660"
  '';

  users.users.zaheenj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    git
    man-pages
  ];
}
