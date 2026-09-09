{ pkgs, ... }:
{
  home.packages = [ pkgs.prismlauncher ];

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/curseforge" = "org.prismlauncher.PrismLauncher.desktop";
    "x-scheme-handler/prismlauncher" = "org.prismlauncher.PrismLauncher.desktop";
    "application/x-modrinth-modpack+zip" = "org.prismlauncher.PrismLauncher.desktop";
  };
}
