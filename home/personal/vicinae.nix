# vicinae: native fast launcher for the desktop (in nixpkgs unstable).
{ pkgs, ... }:
{
  home.packages = [ pkgs.vicinae ];

  xdg.configFile."vicinae/settings.json".source = ./vicinae/settings.json;
}
