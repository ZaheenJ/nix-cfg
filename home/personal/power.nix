# AC/battery hooks: lower brightness + 60 Hz on battery, restore + 240 Hz
# on AC (ported from Arch's /usr/local/bin/{ac,bat}.fish + udev rules, see
# inventory/etc/). Runs as a user service inside the niri session instead of
# udev RUN hooks: no root→user socket hunting, no wait-for-niri race, and the
# correct state is applied at login (udev missed "booted on battery").
# intel_lpmd_control calls from the Arch originals still omitted — intel-lpmd
# isn't packaged on NixOS yet (PLAN.md research item).
{ pkgs, ... }:
let
  powerWatcher = pkgs.writeScript "power-watcher.fish" ''
    #!${pkgs.fish}/bin/fish

    function apply --argument-names online
        if test "$online" = yes
            ${pkgs.brightnessctl}/bin/brightnessctl -d intel_backlight s 50%
            ${pkgs.niri}/bin/niri msg output eDP-1 mode "2560x1600@240.000"
        else
            ${pkgs.brightnessctl}/bin/brightnessctl -d intel_backlight s 10%
            ${pkgs.niri}/bin/niri msg output eDP-1 mode "2560x1600@60.000"
        end
    end

    # Apply current state at session start, then follow UPower change events
    # (only line-power devices print "online:", and only apply transitions so
    # battery-percentage events can't re-clobber manual brightness changes).
    set -g last ""
    for ps in /sys/class/power_supply/*
        if test (cat $ps/type) = Mains
            test (cat $ps/online) = 1; and set -g last yes; or set -g last no
        end
    end
    apply $last

    ${pkgs.upower}/bin/upower --monitor-detail | while read -l line
        string match -rq 'online:\s+(?<state>yes|no)$' -- $line; or continue
        if test "$state" != "$last"
            set -g last $state
            apply $state
        end
    end
  '';
in
{
  systemd.user.services.power-watcher = {
    Unit = {
      Description = "AC/battery brightness and refresh-rate switching";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${powerWatcher}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
