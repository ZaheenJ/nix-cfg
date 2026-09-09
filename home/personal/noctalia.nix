# `config.toml` is the declarative base; Noctalia's Settings UI writes runtime
# overrides to `~/.local/state/noctalia/settings.toml`. Fold durable changes
# back into the base file. PAM is managed by NixOS, not Noctalia's config.
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    settings = ./noctalia/config.toml;
  };
}
