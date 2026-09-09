# Generic Noctalia shell, theme, and desktop behavior.
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    settings = {
      audio.enable_overdrive = true;

      bar.default = {
        background_opacity = 0.75;
        center = [
          "weather"
          "date"
          "media"
          "notifications"
          "tray"
        ];
        end = [
          "caffeine"
          "output_volume"
          "cpu"
          "ram"
          "network"
          "bluetooth"
          "brightness"
          "battery"
        ];
        margin_edge = 5.0;
        margin_ends = 5.0;
        shadow = false;
        start = [ "taskbar" ];
      };

      desktop_widgets.enabled = false;

      idle = {
        behavior_order = [
          "lock"
          "screen-off"
          "suspend"
        ];
        behavior.lock = {
          action = "lock";
          enabled = true;
          timeout = 600;
        };
        behavior.screen-off = {
          action = "screen_off";
          enabled = true;
          timeout = 600;
        };
        behavior.suspend = {
          action = "lock_and_suspend";
          enabled = false;
          timeout = 900;
        };
      };

      location.auto_locate = true;
      lockscreen.blurred_desktop = true;

      lockscreen_widgets = {
        schema_version = 2;
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };
      };

      notification.background_opacity = 0.75;
      osd = {
        background_opacity = 0.75;
        position = "bottom_center";
      };

      shell = {
        font_family = "Iosevka NF";
        polkit_agent = true;
        settings_show_advanced = false;
        panel = {
          control_center_placement = "floating";
          launcher_categories = false;
          open_near_click_control_center = true;
          transparency_mode = "glass";
        };
      };

      theme = {
        builtin = "Tokyo-Night";
        community_palette = "Lilac AMOLED";
        mode = "dark";
        pure_black_dark = true;
        source = "community";
        templates = {
          builtin_ids = [
            "gtk3"
            "gtk4"
            "niri"
            "qt"
          ];
          community_ids = [
            "vicinae"
            "steam"
            "yazi"
          ];
        };
      };

      weather = {
        auto_locate = true;
        unit = "imperial";
      };

      widget.clock.format = "{:%l:%M %p}";
      widget.date = {
        anchor = true;
        format = "{:%l:%M %p %a %d %b}";
      };
      widget.taskbar.group_by_workspace = true;
    };
  };
}
