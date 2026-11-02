{
  wayland.windowManager.niri.settings.binds = {
    "Mod+O" = {
      _props.repeat = false;
      toggle-overview = { };
    };
    "Mod+Ctrl+Slash" = {
      show-hotkey-overlay = { };
    };
    "Mod+B" = {
      _props.hotkey-overlay-title = "Toggle bar";
      spawn = [
        "noctalia"
        "msg"
        "bar-toggle"
      ];
    };
    "Mod+Shift+D" = {
      power-off-monitors = { };
    };
    "Mod+Escape" = {
      _props.allow-inhibiting = false;
      toggle-keyboard-shortcuts-inhibit = { };
    };
    "Mod+R" = {
      _props.hotkey-overlay-title = "Application Launcher";
      spawn = [
        "vicinae"
        "toggle"
      ];
    };
    "Mod+V" = {
      _props.hotkey-overlay-title = "Clipboard Manager";
      spawn = [
        "vicinae"
        "vicinae://launch/clipboard/history?toggle=true"
      ];
    };
    "Mod+Period" = {
      _props.hotkey-overlay-title = "Settings";
      spawn = [
        "noctalia"
        "msg"
        "settings-toggle"
      ];
    };
    "Mod+N" = {
      _props.hotkey-overlay-title = "Notification Center";
      spawn = [
        "noctalia"
        "msg"
        "panel-toggle"
        "control-center"
        "notifications"
      ];
    };
    "Mod+Shift+L" = {
      _props.hotkey-overlay-title = "Lock Screen";
      spawn = [
        "noctalia"
        "msg"
        "session"
        "lock"
      ];
    };
    "Mod+Ctrl+Q" = {
      quit = { };
    };

    XF86AudioRaiseVolume = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "volume-up"
      ];
    };
    XF86AudioLowerVolume = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "volume-down"
      ];
    };
    XF86AudioMute = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "volume-mute"
      ];
    };
    XF86AudioMicMute = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "mic-mute"
      ];
    };
    XF86AudioPlay = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "media"
        "toggle"
      ];
    };
    XF86AudioStop = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "media"
        "stop"
      ];
    };
    XF86AudioPrev = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "media"
        "previous"
      ];
    };
    XF86AudioNext = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "media"
        "next"
      ];
    };
    XF86MonBrightnessUp = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "brightness-up"
      ];
    };
    XF86MonBrightnessDown = {
      _props.allow-when-locked = true;
      spawn = [
        "noctalia"
        "msg"
        "brightness-down"
      ];
    };

    "Mod+X" = {
      _props.repeat = false;
      close-window = { };
    };
    "Mod+F" = {
      maximize-column = { };
    };
    "Mod+Ctrl+F" = {
      fullscreen-window = { };
    };
    "Mod+Space" = {
      toggle-window-floating = { };
    };
    "Mod+Shift+Space" = {
      switch-focus-between-floating-and-tiling = { };
    };
    "Mod+Ctrl+T" = {
      toggle-column-tabbed-display = { };
    };
    "Mod+H" = {
      focus-column-or-monitor-left = { };
    };
    "Mod+J" = {
      focus-window-or-workspace-down = { };
    };
    "Mod+K" = {
      focus-window-or-workspace-up = { };
    };
    "Mod+L" = {
      focus-column-or-monitor-right = { };
    };
    "Mod+Ctrl+H" = {
      move-column-left-or-to-monitor-left = { };
    };
    "Mod+Ctrl+J" = {
      move-window-down-or-to-workspace-down = { };
    };
    "Mod+Ctrl+K" = {
      move-window-up-or-to-workspace-up = { };
    };
    "Mod+Ctrl+L" = {
      move-column-right-or-to-monitor-right = { };
    };
    "Mod+Alt+H" = {
      focus-monitor-left = { };
    };
    "Mod+Alt+L" = {
      focus-monitor-right = { };
    };
    "Mod+Alt+J" = {
      move-column-to-workspace-down = { };
    };
    "Mod+Alt+K" = {
      move-column-to-workspace-up = { };
    };
    "Mod+Alt+Ctrl+H" = {
      move-workspace-to-monitor-left = { };
    };
    "Mod+Alt+Ctrl+J" = {
      move-workspace-down = { };
    };
    "Mod+Alt+Ctrl+L" = {
      move-workspace-to-monitor-right = { };
    };
    "Mod+Alt+Ctrl+K" = {
      move-workspace-up = { };
    };
    "Mod+WheelScrollDown" = {
      _props.cooldown-ms = 150;
      focus-workspace-down = { };
    };
    "Mod+WheelScrollUp" = {
      _props.cooldown-ms = 150;
      focus-workspace-up = { };
    };
    "Mod+Ctrl+WheelScrollDown" = {
      _props.cooldown-ms = 150;
      move-column-to-workspace-down = { };
    };
    "Mod+Ctrl+WheelScrollUp" = {
      _props.cooldown-ms = 150;
      move-column-to-workspace-up = { };
    };
    "Mod+WheelScrollRight" = {
      focus-column-right = { };
    };
    "Mod+WheelScrollLeft" = {
      focus-column-left = { };
    };
    "Mod+Ctrl+WheelScrollRight" = {
      move-column-right = { };
    };
    "Mod+Ctrl+WheelScrollLeft" = {
      move-column-left = { };
    };
    "Mod+Shift+WheelScrollDown" = {
      focus-column-right = { };
    };
    "Mod+Shift+WheelScrollUp" = {
      focus-column-left = { };
    };
    "Mod+Ctrl+Shift+WheelScrollDown" = {
      move-column-right = { };
    };
    "Mod+Ctrl+Shift+WheelScrollUp" = {
      move-column-left = { };
    };

    "Mod+1" = {
      focus-workspace = {
        _args = [ 1 ];
      };
    };
    "Mod+2" = {
      focus-workspace = {
        _args = [ 2 ];
      };
    };
    "Mod+3" = {
      focus-workspace = {
        _args = [ 3 ];
      };
    };
    "Mod+4" = {
      focus-workspace = {
        _args = [ 4 ];
      };
    };
    "Mod+5" = {
      focus-workspace = {
        _args = [ 5 ];
      };
    };
    "Mod+6" = {
      focus-workspace = {
        _args = [ 6 ];
      };
    };
    "Mod+7" = {
      focus-workspace = {
        _args = [ 7 ];
      };
    };
    "Mod+8" = {
      focus-workspace = {
        _args = [ 8 ];
      };
    };
    "Mod+9" = {
      focus-workspace = {
        _args = [ 9 ];
      };
    };
    "Mod+Shift+1" = {
      move-column-to-workspace = {
        _args = [ 1 ];
      };
    };
    "Mod+Shift+2" = {
      move-column-to-workspace = {
        _args = [ 2 ];
      };
    };
    "Mod+Shift+3" = {
      move-column-to-workspace = {
        _args = [ 3 ];
      };
    };
    "Mod+Shift+4" = {
      move-column-to-workspace = {
        _args = [ 4 ];
      };
    };
    "Mod+Shift+5" = {
      move-column-to-workspace = {
        _args = [ 5 ];
      };
    };
    "Mod+Shift+6" = {
      move-column-to-workspace = {
        _args = [ 6 ];
      };
    };
    "Mod+Shift+7" = {
      move-column-to-workspace = {
        _args = [ 7 ];
      };
    };
    "Mod+Shift+8" = {
      move-column-to-workspace = {
        _args = [ 8 ];
      };
    };
    "Mod+Shift+9" = {
      move-column-to-workspace = {
        _args = [ 9 ];
      };
    };
    "Mod+BracketLeft" = {
      consume-or-expel-window-left = { };
    };
    "Mod+BracketRight" = {
      consume-or-expel-window-right = { };
    };
    "Mod+C" = {
      center-column = { };
    };
    "Mod+Ctrl+C" = {
      center-visible-columns = { };
    };
    "Mod+Minus" = {
      set-column-width = {
        _args = [ "-10%" ];
      };
    };
    "Mod+Equal" = {
      set-column-width = {
        _args = [ "+10%" ];
      };
    };
    "Mod+Shift+Minus" = {
      set-window-height = {
        _args = [ "-10%" ];
      };
    };
    "Mod+Shift+Equal" = {
      set-window-height = {
        _args = [ "+10%" ];
      };
    };
    "Mod+S" = {
      screenshot = { };
    };
    "Mod+Ctrl+S" = {
      screenshot-screen = { };
    };
    "Mod+Alt+S" = {
      screenshot-window = { };
    };
    "Mod+Shift+S" = {
      _props.hotkey-overlay-title = "Edit screenshot in clipboard: satty";
      spawn-sh = {
        _args = [ "wl-paste | satty -f -" ];
      };
    };
  };
}
