# Everything tied to this physical machine (ASUS ROG Zephyrus G16 GU605MI:
# Ultra 9 185H + RTX 4070 Max-Q hybrid, OLED 2560x1600@240, IR camera).
# Generic platform config comes from the nixos-hardware gu605my profile
# imported in default.nix; this module holds only what that doesn't cover.
{ inputs, pkgs, ... }:
let
  # AC/battery hooks ported from Arch's /usr/local/bin/{ac,bat}.fish +
  # 99-power-saving.rules (see inventory/etc/). Faithful port EXCEPT the
  # intel_lpmd_control calls: intel-lpmd isn't packaged on NixOS yet
  # (see PLAN.md research item) — re-add when/if it lands.
  # The wait-for-niri loop matches the original; udev kills stuck RUN
  # handlers after its event timeout, same safety net as on Arch.
  powerScript = name: brightness: mode:
    pkgs.writeScript "${name}.fish" ''
      #!${pkgs.fish}/bin/fish
      while not ${pkgs.procps}/bin/pgrep -x niri
          ${pkgs.coreutils}/bin/sleep 1
      end

      ${pkgs.brightnessctl}/bin/brightnessctl -d intel_backlight s ${brightness}

      for dir in /run/user/*
          set socket (${pkgs.fd}/bin/fd "^niri.*.sock" /run/user/1000)
          if test -S $socket
              NIRI_SOCKET=$socket ${pkgs.niri}/bin/niri msg output eDP-1 mode ${mode}
          end
      end
    '';
  batScript = powerScript "bat" "10%" "2560x1600@60.000";
  acScript = powerScript "ac" "50%" "2560x1600@240.000";
in
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
  # asusctl/rog-control-center are used by niri keybinds + spawn-at-startup.

  services.power-profiles-daemon.enable = true;

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # "sufficient" = face OR password, matching Arch; the NixOS default
  # "required" would demand both factors.
  services.howdy = {
    enable = true;
    control = "sufficient";
    # Deltas from inventory/etc/howdy-config.ini that matter; the rest of the
    # Arch config matched upstream defaults. device_path is the IR camera by
    # stable hardware path. Face models: re-enroll post-install (howdy add).
    settings = {
      core.abort_if_lid_closed = true;
      video = {
        device_path = "/dev/v4l/by-path/pci-0000:00:14.0-usb-0:7:1.2-video-index0";
        certainty = 3.5;
        timeout = 4;
        dark_threshold = 80;
        max_height = 320;
      };
    };
  };
  services.linux-enable-ir-emitter.enable = true;

  # Lower brightness + 60 Hz on battery, restore + 240 Hz on AC.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${batScript}"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${acScript}"
  '';
}
