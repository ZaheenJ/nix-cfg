{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 7;
  system.primaryUser = "mandubumz";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  users.users.mandubumz.home = "/Users/mandubumz";
  users.users.mandubumz.shell = pkgs.fish;
}
