# Monitor-specific Noctalia widgets and wallpaper paths.
{ config, ... }:
let
  wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/lakeside_canoe_sunset.jpg";
in
{
  programs.noctalia.settings = {
    lockscreen_widgets = {
      widget_order = [
        "lockscreen-login-box@HDMI-A-1"
        "lockscreen-login-box@eDP-1"
      ];
      widget."lockscreen-login-box@HDMI-A-1" = {
        box_height = 0.0;
        box_width = 0.0;
        cx = 960.0;
        cy = 957.0;
        output = "HDMI-A-1";
        rotation = 0.0;
        type = "login_box";
        settings = {
          background_color = "surface_variant";
          background_opacity = 0.88;
          background_radius = 12.0;
          input_opacity = 1.0;
          input_radius = 6.0;
          show_login_button = true;
        };
      };
      widget."lockscreen-login-box@eDP-1" = {
        box_height = 0.0;
        box_width = 0.0;
        cx = 854.0;
        cy = 944.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "login_box";
        settings = {
          background_color = "surface_variant";
          background_opacity = 0.88;
          background_radius = 12.0;
          input_opacity = 1.0;
          input_radius = 6.0;
          show_login_button = true;
        };
      };
    };

    wallpaper = {
      directory = "${config.home.homeDirectory}/Pictures/wallpapers";
      default.path = wallpaper;
      last.path = wallpaper;
      monitors.HDMI-A-1.path = wallpaper;
      monitors.eDP-1.path = wallpaper;
    };
  };
}
