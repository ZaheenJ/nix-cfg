{ pkgs, ... }:
let
  btrfsMountOptions = [
    "noatime"
    "compress=zstd:1"
    "commit=120"
  ];
in
{
  # Bound build parallelism for this 22-thread / 16 GB machine. The defaults
  # (max-jobs = auto = 22, cores = 0 = all threads) let a single derivation
  # spawn ~22 compilers, each wanting 0.5-2 GB — enough to exhaust 16 GB and
  # thrash zram into a freeze.
  nix.settings = {
    max-jobs = 6;
    cores = 4;
  };

  # Vanilla kernel per user preference (no CachyOS variants).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hybrid-GPU power policy: preserve VRAM across suspend and allow runtime D3
  # power gating when the discrete GPU is idle.
  hardware.nvidia.powerManagement = {
    enable = true;
    finegrained = true;
  };

  services.power-profiles-daemon.enable = true;

  services.intel-lpmd = {
    enable = true;
    configOverrides = {
      PerformanceDef = -1;
      BalancedDef = 0;
      PowersaverDef = 0;
      # Keep CPU placement with lavd; LPMD only tunes power settings.
      Mode = -1;
    };
  };

  systemd.services.intel_lpmd.after = [ "power-profiles-daemon.service" ];

  # Performance and memory policy. zswap is disabled because this host uses
  # zram; the remaining parameters carry over the tuned desktop policy.
  boot.kernelParams = [
    "nowatchdog"
    "zswap.enabled=0"
    "rcutree.enable_rcu_lazy=1"
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  # Safety net against memory-exhaustion freezes. earlyoom kills the biggest
  # hog when free RAM crosses an absolute threshold. Its AND-logic means the
  # free-memory threshold is the effective trigger with freeSwapThreshold=100.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 8;
    freeSwapThreshold = 100;
    enableNotifications = true;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_bytes" = 268435456;
    "vm.dirty_background_bytes" = 67108864;
    "vm.dirty_writeback_centisecs" = 1500;
    "kernel.nmi_watchdog" = 0;
  };

  # Performance-oriented filesystem policy; device UUIDs and subvolume layout
  # remain in hardware-configuration.nix.
  fileSystems = {
    "/".options = btrfsMountOptions;
    "/home".options = btrfsMountOptions;
    "/nix".options = btrfsMountOptions;
    "/var/log".options = btrfsMountOptions;
  };

  # Follow the power profile selected by the laptop's AC/battery watcher.
  services.scx = {
    enable = true;
    package = pkgs.scx.rustscheds;
    scheduler = "scx_lavd";
    extraArgs = [ "--autopower" ];
  };

  systemd.services.scx.after = [ "power-profiles-daemon.service" ];

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
