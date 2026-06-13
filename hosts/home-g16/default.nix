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
  ];

  networking.hostName = "home-g16";

  system.stateVersion = "26.05";
}
