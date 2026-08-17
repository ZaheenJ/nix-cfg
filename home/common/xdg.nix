# XDG user directories: manage ~/.config/user-dirs.dirs and create the standard
# dirs (Desktop, Documents, Downloads, Music, Pictures, Videos, Public,
# Templates). Music feeds services.mpd's musicDirectory default.
{ ... }:
{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
