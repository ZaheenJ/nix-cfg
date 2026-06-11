{ pkgs, ... }:
{
  # Replaces cachyos-gaming-meta with what was actually in use on Arch:
  # steam + umu/protontricks/winetricks/vulkan-tools, standard Proton.
  # Deliberately NO gamemode/gamescope/mangohud (were never installed).
  programs.steam = {
    enable = true;
    protontricks.enable = true;
  };

  environment.systemPackages = with pkgs; [
    umu-launcher
    winetricks
    vulkan-tools
  ];
}
