# Media: mpv (with hwdec), cmus (package only — no rc file exists), vimiv
# (package only — no config files exist), zathura (ported from zathurarc),
# and the MPD-based music stack (MPD + rmpc + mpd-mpris).
# zathura is dependency-installed on Arch but actively used by niri binds.
{ config, pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";
    };
  };

  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      font = "Iosevka NF 12";
      default-bg = "rgba(0,0,0,0.75)";
      default-fg = "rgba(80,0,255,1.0)";
      recolor-lightcolor = "rgba(0,0,0,0)";
      recolor = true;
      statusbar-bg = "rgba(0,0,0,0.2)";
      statusbar-fg = "rgba(80,0,255,1.0)";
      inputbar-bg = "rgba(0,0,0,0.2)";
      inputbar-fg = "rgba(80,0,255,1.0)";
      completion-bg = "rgba(0,0,0,0.0)";
      completion-fg = "rgba(80,0,255,1.0)";
      completion-group-bg = "rgba(0,0,0,0.2)";
      completion-highlight-fg = "rgba(0,0,0,1.0)";
      completion-highlight-bg = "rgba(80,0,255,1.0)";
    };
  };

  # Music stack: MPD (daemon) + rmpc (TUI client) + mpd-mpris (MPRIS bridge so
  # noctalia / playerctl can see and control playback). Music files and their
  # .lrc lyrics both live in ~/Music (via xdg.userDirs.music, set in common/).
  services.mpd = {
    enable = true;
    # musicDirectory defaults to xdg.userDirs.music (~/Music). playlistDirectory
    # defaults to $XDG_DATA_HOME/mpd/playlists; MPD owns playlists, tag cache and
    # state under $XDG_DATA_HOME/mpd.
    # Native PipeWire output so MPD routes through the sound server instead of
    # grabbing an ALSA device exclusively.
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };

  # MPRIS bridge for MPD. mpd.useLocal defaults to services.mpd.enable, so it
  # auto-wires to the local daemon above.
  services.mpd-mpris.enable = true;

  programs.rmpc = {
    enable = true;
    # Partial RON config (rmpc fills the rest from defaults). lyrics_dir is an
    # Option<String>, so the bare-string value needs implicit_some.
    config = ''
      #![enable(implicit_some)]
      (
          address: "127.0.0.1:6600",
          lyrics_dir: "${config.xdg.userDirs.music}",
      )
    '';
  };

  home.packages = with pkgs; [
    cmus
    vimiv-qt
    yt-dlp
    tickrs
  ];
}
