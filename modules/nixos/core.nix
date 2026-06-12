{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Keyboard: niri's xkb config section is empty — it reads layout from
  # locale1, which NixOS populates from these options (localectl on Arch:
  # X11 us/altgr-intl, VC us-acentos).
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };
  console.keyMap = "us-acentos";

  networking.networkmanager.enable = true;
  services.resolved.enable = true;
  # Replaces ufw. Arch's only custom rules were KDE Connect ports for
  # Valent, which the user no longer uses — nothing extra to open.
  networking.firewall.enable = true;

  # Matches Arch zram-generator: zram-size = ram, zstd.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # Realtime priority for audio (Arch used cachyos-settings' @audio rtprio
  # limits; rtkit is the NixOS-idiomatic equivalent).
  security.rtkit.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  services.fwupd.enable = true;
  services.fstrim.enable = true;

  # VIA keyboard (4d4b:3068) and 1915:232a hidraw access (from Arch udev rules).
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="4d4b", ATTRS{idProduct}=="3068", GROUP="users", MODE="0660"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1915", ATTRS{idProduct}=="232a", GROUP="users", MODE="0660"
  '';

  users.users.zaheenj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    git
    man-pages
  ];
}
