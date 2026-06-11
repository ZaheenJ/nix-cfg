{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/desktop-niri.nix
    ../../modules/nixos/asus.nix
    ../../modules/nixos/gaming.nix
  ];

  networking.hostName = "home-g16";

  system.stateVersion = "26.05";
}
