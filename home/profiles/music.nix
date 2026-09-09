# Music services, metadata tools, and music-shell commands.
{ config, pkgs, ... }:
{
  programs.nushell.extraConfig = builtins.readFile ./music/music.nu;
  programs.fish.shellAbbrs.ytda = "yt-dlp --embed-metadata --xattrs -x -f bestaudio --sponsorblock-remove music_offtopic,intro,outro";

  local.nushell.abbreviations.ytda = "yt-dlp --embed-metadata --xattrs -x -f bestaudio --sponsorblock-remove music_offtopic,intro,outro";

  services.mpd = {
    enable = true;
    extraConfig = ''
      auto_update "yes"

      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };

  services.mpd-mpris.enable = true;

  programs.rmpc = {
    enable = true;
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
    yt-dlp
    songrec
    opustags
    opus-tools
    kakasi
    viu
  ];
}
