# Everything tied to this physical machine (ASUS ROG Zephyrus G16 GU605MI:
# Ultra 9 185H + RTX 4070 Max-Q hybrid, OLED 2560x1600@240, IR camera).
# Generic platform config comes from the nixos-hardware gu605my profile
# imported in default.nix; this module holds only what that doesn't cover.
{ inputs, pkgs, ... }:
{
  ## Graphics — hybrid Meteor Lake Arc iGPU (PCI 00:02.0) + RTX 4070 Max-Q
  ## (PCI 01:00.0). videoDrivers, open driver, modesetting, dynamicBoost,
  ## prime offload + bus IDs, Intel media/compute runtimes and early-KMS
  ## i915 all come from the nixos-hardware profile.

  # The profile's shared/backlight.nix would add i915.enable_dpcd_backlight=1,
  # conflicting with our Arch-verified =3 below (kernelParams just
  # concatenates). Disable it and port its two useful NVreg params instead.
  disabledModules = [ "${inputs.nixos-hardware}/asus/zephyrus/shared/backlight.nix" ];
  boot.kernelParams = [
    # Force the Intel proprietary DPCD backlight interface — this OLED's VBT
    # misreports its backlight type, so detection (=1 / default) fails.
    "i915.enable_dpcd_backlight=3"
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

  ## Dual-boot: BLS entry for Arch (CachyOS) on the shared ESP. lanzaboote
  ## ignores boot.loader.systemd-boot.extraEntries, so ship the file via
  ## tmpfiles; lzbt's ESP garbage collection only sweeps EFI/nixos and
  ## nixos-* in EFI/Linux, so loader/entries/arch.conf survives rebuilds.
  ## Kernel and cmdline taken verbatim from Arch's refind_linux.conf
  ## (2026-06-12); the kernel is sbctl-signed on the Arch side, so it
  ## verifies under Secure Boot.
  systemd.tmpfiles.rules =
    let
      archEntry = pkgs.writeText "arch.conf" ''
        title CachyOS (Arch)
        sort-key z-arch
        linux /vmlinuz-linux-cachyos
        initrd /intel-ucode.img
        initrd /initramfs-linux-cachyos.img
        options quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3 zswap.enabled=0 nowatchdog vt.global_cursor_default=0 splash i915.enable_dpcd_backlight=3 rcutree.enable_rcu_lazy=1 rw rootflags=subvol=/@ root=UUID=b34a2639-b192-4add-a2ba-3deb931288ce
      '';
    in
    [ "C+ /boot/loader/entries/arch.conf - - - - ${archEntry}" ];

  ## ASUS vendor daemons + power behavior.

  # services.asusd comes from the nixos-hardware gu605my profile (mkDefault);
  # hardware control is via the asusd daemon + asusctl CLI (niri keybinds).
  # The rog-control-center GUI/tray is intentionally not autostarted — asusctl
  # covers everything and its GUI kept crashing (coredump spam in the journal).

  services.power-profiles-daemon.enable = true;

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # Face auth is gaze (replaced howdy). No linux-enable-ir-emitter: this Sonix
  # 3277:0051 camera's IR emitter is motion/proximity-reactive (fires in
  # hardware when someone is in front of it), not software-controlled — probing
  # it finds nothing and can hang. So gaze just reads the IR node with the
  # emitter left alone (emitter_enabled defaults false).
  services.gaze = {
    enable = true;
    # Generate /etc/gaze/config.toml read-only from `settings` (we don't use the
    # GUI settings page, so keep it fully declarative rather than seed-and-mutate).
    mutableConfig = false;
    # Only short-lived auth processes. Deliberately NOT "login" or "greetd":
    # greetd's PAM does `auth substack login`, so putting gaze on "login" pulls
    # pam_gaze.so into greetd's long-lived session-worker too. There it (a) pins
    # ~2.8 GB of mlock'd per-CPU inference buffers it never frees — the main
    # driver of the 2026-07 memory-freeze — and (b) runs before gnome_keyring so
    # a face login never unlocks the login keyring ("password no longer matches"
    # popup). The noctalia lockscreen unlocks via gazed over D-Bus, not PAM
    # "login", so it keeps face auth regardless. polkit-1 broke under howdy (it
    # opened the camera in the agent's process); gaze does camera work in the
    # root daemon, so it's fine here.
    pam.defaultServices = [
      "sudo"
      "polkit-1"
    ];
    # The daemon runs as root with no user PipeWire session (and none exists at
    # the greeter/lockscreen), so drive both cameras directly via V4L2 instead
    # of the "primary"/pipewiresrc default. Stable by-path nodes: …-1.0-… is the
    # color webcam, …-1.2-… is the IR camera.
    settings = {
      security.level = "medium";
      cameras = {
        rgb = "v4l2src device=/dev/v4l/by-path/pci-0000:00:14.0-usb-0:7:1.0-video-index0";
        ir = "v4l2src device=/dev/v4l/by-path/pci-0000:00:14.0-usb-0:7:1.2-video-index0";
        # IR frames from this camera hover right at ~16-36 luma even with the
        # emitter firing, so the default 30 rejects many valid frames as "not
        # enough light" and enrollment/auth only intermittently gets through.
        # Lower the gate to accept the dim-but-valid IR feed.
        dark_luma_threshold = 15;
      };
      auth = {
        abort_if_ssh = true;
        abort_if_lid_closed = true;
      };
      liveness = {
        enabled = true;
        threshold = 0.8;
        max_frames = 40;
      };
      enrollment.max_templates = 2;
      storage.encrypt_templates = false;
    };
  };

  # asus-shutdown (from the asus profile) ignores SIGTERM by design and sets
  # SendSIGKILL=no, so every nixos-rebuild switch that tries to restart it hangs
  # on stop and fails with a timeout — making switch-to-configuration exit 4 even
  # though nothing is actually wrong. Leave it running across switches; the new
  # version takes effect at the next boot.
  systemd.services.asus-shutdown = {
    restartIfChanged = false;
    stopIfChanged = false;
  };

  # AC/battery brightness + refresh-rate switching is a user service now
  # (home/personal/power.nix) watching UPower events — it replaced the Arch
  # udev RUN hooks (root poking the user's niri socket, racing niri at boot).
  services.upower.enable = true;
}
