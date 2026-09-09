# Cursor, GTK, Qt, and MIME theming for the personal desktop.
# GTK/Qt color theming comes from noctalia's theme templates (gtk3/gtk4/qt
# in [theme.templates]); the old oomox-BWnB theme was dropped per user.
{ pkgs, config, ... }:
{
  # Cursor: Bibata-Modern-Classic, 24px — matches niri config.kdl and GTK settings.
  home.pointerCursor = {
    enable = true; # now required explicitly by home-manager
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
  };

  # GTK theme, font, and dark preference.
  # adw-gtk3 is the libadwaita GTK3 backport; it's the base theme that noctalia's
  # gtk3/gtk4 templates recolor via @define-color in ~/.config/gtk-*/noctalia.css.
  # Without it, GTK3 apps fall back to built-in Adwaita and ignore those color
  # names (GTK4/libadwaita apps consume them natively, so they were already fine).
  gtk = {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    font = {
      name = "Iosevka Nerd Font";
      size = 11;
    };
  };
  gtk.colorScheme = "dark";

  qt = {
    enable = true;
    platformTheme = {
      name = "qt6ct";
      package = pkgs.qt6Packages.qt6ct;
    };
    qt6ctSettings = {
      Appearance = {
        color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/noctalia.conf";
        custom_palette = true;
        standard_dialogs = "default";
        style = "Fusion";
      };
      Fonts = {
        fixed = ''"Noto Sans,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'';
        general = ''"Iosevka Nerd Font,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
      };
      Interface = {
        activate_item_on_single_click = 1;
        buttonbox_layout = 0;
        cursor_flash_time = 1000;
        dialog_buttons_have_icons = 1;
        double_click_interval = 400;
        gui_effects = "@Invalid()";
        keyboard_scheme = 2;
        menus_have_icons = true;
        show_shortcuts_in_context_menus = true;
        stylesheets = "@Invalid()";
        toolbutton_style = 4;
        underline_shortcut = 1;
        wheel_scroll_lines = 3;
      };
      Troubleshooting = {
        force_raster_widgets = 1;
        ignored_applications = "@Invalid()";
      };
    };
  };
}
