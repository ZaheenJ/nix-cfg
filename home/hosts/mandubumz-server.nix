{ inputs, ... }:
{
  imports = [
    inputs.nix-plist-manager.homeManagerModules.default
    ../profiles/base.nix
    ../profiles/cloud-ai-tools.nix
  ];

  home.username = "mandubumz";
  home.homeDirectory = "/Users/mandubumz";
  home.stateVersion = "26.05";

  programs.nix-plist-manager = {
    enable = true;
    options.applications.systemSettings.keyboard = {
      keyRepeatRate = 1;
      delayUntilRepeat = 13;
    };
  };

  xdg.enable = true;
  programs.nushell.configDir = "Library/Application Support/nushell";
}
