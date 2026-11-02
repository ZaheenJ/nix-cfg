{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  # Old system generations accumulate in /nix until GC'd. Weekly GC of
  # generations older than two weeks keeps rollback headroom without growth.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;

  # IP-geolocation timezone: sets tz via timedatectl at boot + hourly timer.
  # The module forces time.timeZone = null (imperative management).
  services.tzupdate.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "us-acentos";

  networking.networkmanager.enable = true;
  services.resolved.enable = true;
  # Replaces ufw. Arch's only custom rules were KDE Connect ports for
  # Valent, which the user no longer uses — nothing extra to open.
  networking.firewall.enable = true;

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    git
    man-pages
  ];
}
