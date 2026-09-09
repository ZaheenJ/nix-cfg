# Shared Git behavior and user-wide identity.
{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    ignores = [
      "**/.claude/settings.local.json"
    ];

    settings = {
      user.name = "ZaheenJ";
      user.email = "zaheen.jamil@gmail.com";
    };
  };
}
