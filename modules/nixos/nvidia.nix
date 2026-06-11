{ pkgs, ... }:
{
  # Hybrid graphics: Meteor Lake Arc iGPU (PCI 00:02.0) + RTX 4070 Max-Q
  # (PCI 01:00.0), offload mode as on Arch (nvidia-prime + supergfxd Hybrid).
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    # Sets NVreg_PreserveVideoMemoryAllocations=1 (suspend fix from Arch
    # modprobe.d) among others; finegrained = runtime D3 power gating.
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      nvidia-vaapi-driver # was libva-nvidia-driver on Arch
    ];
  };
}
