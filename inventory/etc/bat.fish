#!/usr/bin/env fish

intel_lpmd_control ON

while not pgrep -x niri
    sleep 1
end

brightnessctl -d intel_backlight s 10%

for dir in /run/user/*
    set socket (fd "^niri.*.sock" /run/user/1000)
    if test -S $socket
        # echo -e "keyword monitor eDP-1, 2560x1600@60, 0x0, auto, vrr, 1" | socat - UNIX-CONNECT:$socket
        NIRI_SOCKET=$socket niri msg output eDP-1 mode 2560x1600@60.000
    end
end
