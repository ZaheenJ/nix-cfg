{
  # Keyboard: niri's xkb config section is empty — it reads layout from
  # locale1, which NixOS populates from these options (localectl on Arch:
  # X11 us/altgr-intl, VC us-acentos).
  services.xserver.xkb = {
    layout = "us";
    # variant = "altgr-intl"; # breaks Mod + Alt + Key Niri binds
    options = "terminate:ctrl_alt_bksp,caps:escape,shift:both_capslock_cancel";
  };

  hardware.bluetooth.enable = true;

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
  services.printing.enable = true;
}
