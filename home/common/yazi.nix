# yazi terminal file manager. Shell wrapper (`y`) cd's the parent shell into
# yazi's last directory on exit; fish + nushell integrations provide it.
#
# Integrations:
# - zoxide: yazi ships a bundled `zoxide` plugin (bound to `z`) that jumps via
#   zoxide's frecency DB; the interactive picker uses fzf. `update_db = true`
#   makes yazi feed its OWN directory changes back into zoxide, so it's
#   two-way, not one-way. The bundled `fzf` plugin (`Z`) finds files/dirs.
# - git: yaziPlugins.git shows per-file git status; needs the fetchers below
#   plus the require():setup() call the HM module writes into init.lua.
# - previews: extraPackages put the optional previewers on the wrapper's PATH.
{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;

    # Optional previewers. These four are ALREADY in yazi's own closure, so
    # exposing their binaries on the wrapper's PATH costs ~0 extra bytes —
    # cheap enough to ship in the shared base. ffmpeg (video thumbnails) is
    # NOT here: its closure adds ~700 MiB, so it's opt-in per host (personal
    # laptop adds it in home/personal/media.nix). fd/ripgrep/zoxide/fzf/
    # wl-clipboard are already global and resolve from PATH.
    extraPackages = with pkgs; [
      poppler-utils # PDF previews (pdftoppm)
      imagemagick # SVG/HEIC and image fallbacks
      _7zz # archive browsing/extraction
      jq # JSON previews
    ];

    plugins = {
      git = {
        package = pkgs.yaziPlugins.git;
        setup = true;
        settings.order = 1500; # order of git status signs in the linemode
      };
    };

    # Bundled zoxide plugin: record yazi's navigation back into the zoxide DB.
    # (git's setup() is emitted by the HM module before this.)
    initLua = ''
      require("zoxide"):setup { update_db = true }
    '';

    # yazi 26.x fetcher schema: `url` (was `name`) + a required `group`.
    # `id` is still accepted at v26.1.22; drop it once yazi > 26.1.22.
    settings.plugin.prepend_fetchers = [
      {
        id = "git";
        url = "*";
        run = "git";
        group = "git";
      }
      {
        id = "git";
        url = "*/";
        run = "git";
        group = "git";
      }
    ];
  };
}
