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
  # asusctl/rog-control-center were dependency-installed on Arch but are used
  # by niri keybinds (asusctl -n/-p) and spawn-at-startup (rog-control-center).
  services.asusd.enable = true;

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
  };
  services.linux-enable-ir-emitter.enable = true;

  # Lower brightness + 60 Hz on battery, restore + 240 Hz on AC.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${batScript}"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${acScript}"
  '';
}
