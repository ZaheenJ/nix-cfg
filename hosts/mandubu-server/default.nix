{ pkgs, ... }:
{
  imports = [ ./keyboard.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfreePackages = [ "antigravity-cli" ];

  system.stateVersion = 7;
  system.primaryUser = "mandubumz";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish.enable = true;
  services.openssh.enable = true;
  services.tailscale.enable = true;
  security.pam.services.sudo_local.touchIdAuth = true;
  environment.shells = [ pkgs.fish ];
  users.users.mandubumz.home = "/Users/mandubumz";
  users.users.mandubumz.shell = pkgs.fish;
}
