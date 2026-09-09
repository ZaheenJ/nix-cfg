# Home Manager profile for the personal ASUS laptop.
{ ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/ai-tools.nix
    ../profiles/cli-extras.nix
    ../profiles/desktop-agnostic.nix
    ../profiles/browser-extras.nix
    ../profiles/communications.nix
    ../profiles/media.nix
    ../profiles/music.nix
    ../profiles/gaming.nix
    ../profiles/personal-sync.nix
    ./home-g16/power.nix
    ./home-g16/monitoring.nix

    # Phase-2 desktop modules remain available and unchanged.
    ../personal/niri.nix
    ../personal/noctalia.nix
    ../personal/vicinae.nix
    ../personal/desktop-tools.nix
    ../personal/theming.nix
  ];

  home.username = "zaheenj";
  home.homeDirectory = "/home/zaheenj";
  home.stateVersion = "26.05";

  programs.taskwarrior.extraConfig = ''
    # Include machine-local sync credentials (WingTask)
    include ~/.config/task/sync.rc
  '';
}
