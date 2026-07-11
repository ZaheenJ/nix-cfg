{ inputs, ... }:
{
  imports = [
    # GU605MY = same platform as this GU605MI (4090 vs 4070, both Ada).
    # Brings: hwdb key fixes, nvidia dynamicBoost, early-KMS i915, Intel
    # media/compute runtimes (+32-bit), prime offload + bus IDs, asusd.
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu605my
    ./hardware-configuration.nix
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop-niri.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/tailscale.nix
  ];

  networking.hostName = "home-g16";

  # Bound build parallelism for this 22-thread / 16 GB machine. The defaults
  # (max-jobs = auto = 22, cores = 0 = all threads) let a single derivation
  # spawn ~22 compilers, each wanting 0.5-2 GB — enough to exhaust 16 GB and
  # thrash zram into a freeze. Cap concurrent derivations and per-build -j so
  # a rebuild can't blow past RAM. (An OOM killer is the real guarantee; this
  # just keeps the common case well clear of the cliff.)
  nix.settings = {
    max-jobs = 6;
    cores = 4;
  };

  system.stateVersion = "26.05";
}
