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
    ../profiles/niri-desktop.nix
    ./home-g16/power.nix
    ./home-g16/monitoring.nix
    ./home-g16/kanshi.nix
    ./home-g16/niri.nix
    ./home-g16/noctalia.nix
  ];

  home.username = "zaheenj";
  home.homeDirectory = "/home/zaheenj";
  home.stateVersion = "26.05";

  programs.taskwarrior.extraConfig = ''
    # Include machine-local sync credentials (WingTask)
    include ~/.config/task/sync.rc
  '';
}
