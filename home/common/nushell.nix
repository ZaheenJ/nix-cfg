# nushell: primary interactive shell (ghostty starts it).
# Zoxide and starship integrations are owned by cli.nix / starship.nix via
# their respective enableNushellIntegration flags — not duplicated here.
{ config, lib, ... }:
let
  sessionPath = map (builtins.replaceStrings
    [ "$HOME" ]
    [ config.home.homeDirectory ]
  ) config.home.sessionPath;
in
{
  options.local.nushell.abbreviations = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    internal = true;
  };

  config.programs.nushell = {
    enable = true;

    # env.nu: the old imperative zoxide init call is replaced by
    # programs.zoxide.enableNushellIntegration in cli.nix.
    configFile.text = ''
      let abbreviations = ${lib.hm.nushell.toNushell { } config.local.nushell.abbreviations}
      ${builtins.readFile ./nushell/config.nu}
    '';

    extraEnv = ''
      $env.PATH = (${lib.hm.nushell.toNushell { } sessionPath} ++ $env.PATH) | uniq
    '';
  };
}
