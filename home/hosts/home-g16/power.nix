# Lower brightness and refresh rate on battery; restore them on AC.
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
