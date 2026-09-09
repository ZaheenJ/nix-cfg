# nushell: primary interactive shell (ghostty starts it).
# Zoxide and starship integrations are owned by cli.nix / starship.nix via
# their respective enableNushellIntegration flags — not duplicated here.
{ ... }:
{
  programs.nushell = {
    enable = true;

    # env.nu: the old imperative zoxide init call is replaced by
    # programs.zoxide.enableNushellIntegration in cli.nix.
    configFile.source = ./nushell/config.nu;

    # Profile-specific music commands: metadata-adder, music-cover,
    # music-lyrics, and related helpers.
    extraConfig = builtins.readFile ./nushell/music.nu;
  };
}
