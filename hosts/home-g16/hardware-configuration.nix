# Hand-written from the running Arch system (see inventory/);
# cross-check against `nixos-generate-config --root /mnt/nixos` at install time.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
    "usbhid"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1198bc8f-1186-44a5-aed4-e9a0bbb80ab6";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "noatime"
      "compress=zstd:1"
      "commit=120"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/1198bc8f-1186-44a5-aed4-e9a0bbb80ab6";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "noatime"
      "compress=zstd:1"
      "commit=120"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/1198bc8f-1186-44a5-aed4-e9a0bbb80ab6";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "noatime"
      "compress=zstd:1"
      "commit=120"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/1198bc8f-1186-44a5-aed4-e9a0bbb80ab6";
    fsType = "btrfs";
    options = [
      "subvol=@log"
      "noatime"
      "compress=zstd:1"
      "commit=120"
    ];
  };

  # Shared ESP (Windows + Arch + NixOS) — never reformat.
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E60A-6840";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # Meteor Lake NPU (detected by nixos-generate-config cross-check)
  hardware.cpu.intel.npu.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
