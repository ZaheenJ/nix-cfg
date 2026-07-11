# XDG user directories: manage ~/.config/user-dirs.dirs and create the standard
# dirs (Desktop, Documents, Downloads, Music, Pictures, Videos, Public,
# Templates). Music feeds services.mpd's musicDirectory default. `projects` is a
# non-standard home-manager extra we don't want, so it's omitted.
{ ... }:
{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    projects = null;
  };
}
