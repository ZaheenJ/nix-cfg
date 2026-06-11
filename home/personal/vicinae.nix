# vicinae: native fast launcher for the desktop (in nixpkgs unstable).
# settings.json is app-written runtime state (like noctalia's) — copied to
# the new /home in Phase 4, not managed read-only by home-manager.
{ pkgs, ... }:
{
  home.packages = [ pkgs.vicinae ];
}
