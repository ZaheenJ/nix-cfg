#!/usr/bin/env fish

intel_lpmd_control AUTO

while not pgrep -x niri
    sleep 1
end

brightnessctl -d intel_backlight s 50%

for dir in /run/user/*
    set socket (fd "^niri.*.sock" /run/user/1000)
    if test -S $socket
        # echo -e "keyword monitor eDP-1, 2560x1600@240, 0x0, auto, vrr, 1" | socat - UNIX-CONNECT:$socket
        NIRI_SOCKET=$socket niri msg output eDP-1 mode 2560x1600@240.000
    end
end
