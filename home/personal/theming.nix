# Cursor, GTK, Qt, and MIME theming for the personal desktop.
# GTK/Qt color theming comes from noctalia's theme templates (gtk3/gtk4/qt
# in [theme.templates]); the old oomox-BWnB theme was dropped per user.
{ pkgs, ... }:
{
  # Cursor: Bibata-Modern-Classic, 24px — matches niri config.kdl and GTK settings.
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
  };

  # GTK: icon theme + font + dark preference. Theme name omitted (see above).
  # Note: gtk-icon-theme-name in settings.ini was "Bibata-Modern-Classic" (same as
  # cursor), which is likely an Arch-side artefact; bibata-cursors does not ship
  # a GTK icon theme. Setting package = null means niri/GTK will use whatever
  # icon theme is already installed system-wide.
  gtk = {
    enable = true;
    iconTheme = {
      package = null;
      name = "Bibata-Modern-Classic";
    };
    font = {
      name = "Iosevka Nerd Font";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = false;
      gtk-cursor-theme-name = "Bibata-Modern-Classic";
      gtk-cursor-theme-size = 24;
    };
    gtk4.extraConfig = {
      gtk-cursor-theme-name = "Bibata-Modern-Classic";
    };
  };

  # Qt: use qt6ct for platform theme; set QT_QPA_PLATFORMTHEME in niri config.kdl.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  # qt6ct.conf is declarative: it only stores a POINTER
  # (color_scheme_path -> colors/noctalia.conf); noctalia's qt template
  # rewrites that target file on theme changes, so colors stay dynamic while
  # this config is read-only. Font/style/icon tweaks: edit ./qt6ct/qt6ct.conf
  # here, not the qt6ct GUI (it can't save).
  xdg.configFile."qt6ct/qt6ct.conf".source = ./qt6ct/qt6ct.conf;

  # MIME associations (ported from ~/.config/mimeapps.list).
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };
}
