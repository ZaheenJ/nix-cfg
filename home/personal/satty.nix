# satty: screenshot annotation tool. No ~/.config/satty/ exists on Arch,
# so only the package is added; defaults are used.
{ pkgs, ... }:
{
  home.packages = [ pkgs.satty ];
}
