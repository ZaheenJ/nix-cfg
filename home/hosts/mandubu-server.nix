{ ... }:
{
  imports = [ ../profiles/base.nix ];

  home.username = "mandubumz";
  home.homeDirectory = "/Users/mandubumz";
  home.stateVersion = "26.05";

  xdg.enable = true;
}
