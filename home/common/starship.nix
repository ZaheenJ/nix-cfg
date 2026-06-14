# starship: cross-shell prompt. Fish and nushell integrations enabled here.
{ ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;

    presets = [ "nerd-font-symbols" ];
  };
}
