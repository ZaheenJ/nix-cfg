# ASUS-specific niri policy and application bindings.
{ ... }:
{
  wayland.windowManager.niri = {
    systemd.enable = false;
    portalPackage = null;
    xwaylandSatellitePackage = null;

    settings = {
      input.disable-power-key-handling = { };

      binds = {
        "Mod+Shift+R" = {
          _props = {
            hotkey-overlay-title = "Reboot";
            allow-when-locked = true;
          };
          spawn = [
            "systemctl"
            "reboot"
          ];
        };
        "Mod+Shift+P" = {
          _props = {
            hotkey-overlay-title = "Poweroff";
            allow-when-locked = true;
          };
          spawn = [
            "systemctl"
            "poweroff"
          ];
        };
        XF86KbdBrightnessUp = {
          _props = {
            hotkey-overlay-title = "Keyboard brightness up";
            allow-when-locked = true;
          };
          spawn = [
            "asusctl"
            "-n"
          ];
        };
        XF86KbdBrightnessDown = {
          _props = {
            hotkey-overlay-title = "Keyboard brightness down";
            allow-when-locked = true;
          };
          spawn = [
            "asusctl"
            "-p"
          ];
        };
        "Mod+T" = {
          _props.hotkey-overlay-title = "Open Terminal";
          spawn = [ "ghostty" ];
        };
        "Mod+M" = {
          _props.hotkey-overlay-title = "Music player: rmpc";
          spawn = [
            "ghostty"
            "-e"
            "rmpc"
          ];
        };
        "Mod+W" = {
          _props.hotkey-overlay-title = "Web browser: Firefox";
          spawn = [ "firefox" ];
        };
        "Mod+I" = {
          _props.hotkey-overlay-title = "Incognito web browser: Firefox";
          spawn = [
            "firefox"
            "--private-window"
          ];
        };
        "Mod+Y" = {
          _props.hotkey-overlay-title = "Youtube";
          spawn = [
            "firefox"
            "--new-window"
            "youtube.com"
          ];
        };
        "Mod+Z" = {
          _props.hotkey-overlay-title = "PDF Reader: zathura";
          spawn = [ "zathura" ];
        };
        "Mod+D" = {
          _props.hotkey-overlay-title = "Discord";
          spawn = [ "vesktop" ];
        };
      };

      _children = [
        {
          output = {
            _args = [ "eDP-1" ];
            "focus-at-startup" = { };
            variable-refresh-rate = { };
          };
        }
        {
          "/-debug" = {
            "render-drm-device" = {
              _args = [ "/dev/dri/renderD129" ];
            };
          };
        }
        {
          window-rule._children = [
            {
              match._props = {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              };
            }
            { open-floating = true; }
          ];
        }
        {
          window-rule._children = [
            { match._props.app-id = "ghostty$"; }
            { match._props.app-id = "^vesktop$"; }
            { match._props.app-id = "zathura$"; }
            { background-effect.blur = true; }
          ];
        }
      ];
    };
  };
}
