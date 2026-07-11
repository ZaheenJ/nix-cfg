# nushell: primary interactive shell (ghostty starts it).
# Zoxide and starship integrations are owned by cli.nix / starship.nix via
# their respective enableNushellIntegration flags — not duplicated here.
{ ... }:
{
  programs.nushell = {
    enable = true;

    # env.nu: the old imperative zoxide init call is replaced by
    # programs.zoxide.enableNushellIntegration in cli.nix.
    envFile.text = "";

    configFile.text =
      builtins.readFile ./nushell/config.nu
      + "\n"
      # music library commands: metadata-adder, music-cover, music-lyrics,
      + builtins.readFile ./nushell/music.nu;
  };
}
