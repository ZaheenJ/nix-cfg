{ inputs, pkgs, ... }:
{
  # Hybrid graphics: Meteor Lake Arc iGPU (PCI 00:02.0) + RTX 4070 Max-Q
  # (PCI 01:00.0). Base config (videoDrivers, open driver, modesetting,
  # dynamicBoost, prime offload + bus IDs, Intel media/compute runtimes,
  # early-KMS i915) comes from the nixos-hardware gu605my profile imported
  # in hosts/home-g16; this module holds only what the profile doesn't set.

  # The profile's shared/backlight.nix would add i915.enable_dpcd_backlight=1,
  # conflicting with our Arch-verified =3 in boot.nix (kernelParams just
  # concatenates). Disable it and port its two useful NVreg params below.
  disabledModules = [ "${inputs.nixos-hardware}/asus/zephyrus/shared/backlight.nix" ];
  boot.kernelParams = [
    # Keep the NVIDIA driver from registering a bogus backlight device in
    # hybrid mode (from the disabled backlight.nix; intel_backlight rules).
    "nvidia.NVreg_EnableBacklightHandler=0"
    "nvidia.NVReg_RegistryDwords=EnableBrightnessControl=0"
  ];

  hardware.nvidia = {
    # Sets NVreg_PreserveVideoMemoryAllocations=1 (suspend fix from Arch
    # modprobe.d) among others; finegrained = runtime D3 power gating.
    # The nixos-hardware profile does NOT cover these.
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };

  # Meteor Lake is Gen12+: only the modern media driver is needed; the
  # profile's default (null) would also pull in the legacy intel-vaapi-driver.
  hardware.intelgpu.vaapiDriver = "intel-media-driver";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Intel drivers come from the profile (incl. 32-bit + oneVPL + compute).
    extraPackages = with pkgs; [
      nvidia-vaapi-driver # was libva-nvidia-driver on Arch
    ];
  };
}
