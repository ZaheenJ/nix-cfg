# Cursor, GTK, and Qt appearance for the niri desktop.
{ pkgs, config, ... }:
{
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
  };

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
