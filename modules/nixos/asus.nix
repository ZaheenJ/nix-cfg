{ pkgs, ... }:
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
