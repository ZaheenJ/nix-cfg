{ ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/cloud-ai-tools.nix
  ];

  home.username = "mandubumz";
  home.homeDirectory = "/Users/mandubumz";
  home.stateVersion = "26.05";

  xdg.enable = true;
  programs.nushell.configDir = "Library/Application Support/nushell";
}
