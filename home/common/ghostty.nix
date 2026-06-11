# ghostty: terminal emulator. Launches nushell as the shell.
# The ghostty config uses repeated palette keys (palette = 0=#... through 15)
# which the HM ghostty settings attrset cannot express. Config is vendored
# verbatim; ghostty is installed via home.packages to avoid HM module
# collision on the config path.
{ pkgs, ... }:
{
  home.packages = [ pkgs.ghostty ];

  xdg.configFile."ghostty/config".source = ./ghostty/config;
}
