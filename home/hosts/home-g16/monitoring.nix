{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nvtopPackages.full
    powerstat
  ];
}
