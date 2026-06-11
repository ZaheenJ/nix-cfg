# Faithful port of ~/.gitconfig (identity + git-lfs) and ~/.config/git/ignore.
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
