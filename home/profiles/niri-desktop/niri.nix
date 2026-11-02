# Generic niri configuration. Hardware and application exceptions are layered
# by the host module.
{ config, ... }:
{
  imports = [ ./niri/keybindings.nix ];

  wayland.windowManager.niri = {
    enable = true;
    settings = {
      environment = {
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORM = "wayland;xcb";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      input = {
        keyboard = {
          repeat-delay = 200;
          repeat-rate = 50;
          numlock = { };
        };
        touchpad = {
          tap = { };
          dwt = { };
          natural-scroll = { };
          accel-profile = {
            _args = [ "flat" ];
          };
        };
        warp-mouse-to-focus = { };
        focus-follows-mouse._props.max-scroll-amount = "20%";
      };

      cursor = {
        xcursor-theme = "Bibata-Modern-Classic";
        xcursor-size = 24;
        hide-when-typing = { };
      };

      layout = {
        gaps = 5;
        center-focused-column = {
          _args = [ "never" ];
        };
        preset-column-widths._children = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        default-column-width = {
          proportion = 0.5;
        };
        focus-ring.off = { };
        border = {
          width = 2;
          inactive-color = "#444444";
          urgent-color = "#ff0000";
          active-gradient._props = {
            from = "#0000ff";
            to = "#ff00ff";
          };
        };
        tab-indicator = {
          hide-when-single-tab = { };
          place-within-column = { };
          width = 8;
          gap = 4;
          corner-radius = 10;
        };
      };

      hotkey-overlay.skip-at-startup = { };
      prefer-no-csd = { };
      screenshot-path = "${config.xdg.userDirs.pictures}/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      gestures."hot-corners".off = { };

      blur = {
        passes = 3;
        offset = 3;
        noise = 0.02;
        saturation = 1.5;
      };

      _children = [
        { spawn-at-startup._args = [ "noctalia" ]; }
        {
          spawn-at-startup._args = [
            "vicinae"
            "server"
          ];
        }
        {
          window-rule = {
            geometry-corner-radius = 20;
            clip-to-geometry = true;
            tiled-state = true;
            draw-border-with-background = false;
          };
        }
        {
          window-rule = {
            match._props.app-id = "dev.noctalia.Noctalia.Settings";
            open-floating = true;
            default-column-width = {
              fixed = 1080;
            };
            default-window-height = {
              fixed = 920;
            };
          };
        }
        {
          layer-rule._children = [
            { match._props.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"; }
            { match._props.namespace = "^vicinae$"; }
            { background-effect.xray = false; }
          ];
        }
      ];

      debug.honor-xdg-activation-with-invalid-serial = { };
    };
    extraConfig = ''
      include optional=true "noctalia.kdl"
    '';
  };
}
