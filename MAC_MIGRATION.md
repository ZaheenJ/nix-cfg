# macOS migration checklist

## Deferred configuration

- [ ] Port the custom fish Helix key bindings. They currently use Linux-oriented
  `sed -z` and `xsel`; macOS uses fish vi bindings until this is adapted.
- [ ] Adapt the Helix `C-z` PDF helper, which currently calls `xdg-open`. Use
  macOS `open` or Preview when revisiting it. Zathura is not required for this
  helper.
- [ ] Review `desktop-agnostic.nix` before importing it. XDG config paths work
  on macOS, but Home Manager's `xdg.mimeApps` support is Linux-only.
- [ ] Review the remaining profiles before adding them: `ai-tools`,
  `cli-extras`, `browser-extras`, `communications`, `media`, `music`,
  `gaming`, `personal-sync`, and `niri-desktop`.
- [ ] Port or replace the host-specific Niri, Noctalia, power, monitoring, and
  display configuration. These are currently Linux desktop/laptop concerns.
- [ ] Add local AI, Jellyfin, and Minecraft service configuration after
  evaluating macOS support, resource use, and service lifecycle needs.
- [ ] Design sync and backup separately. Syncthing can synchronize files, but
  a separate versioned backup is needed to recover deleted or changed data.

## MacBook operation and storage

- [ ] Decide how the MacBook should stay awake with its lid closed when it is
  serving requests, including whether this should apply only on power and/or
  while connected to a network.
- [ ] Plan external storage: the roughly 500 GB internal drive is shared by
  macOS, Nix, applications, media, local AI models, and backups. Keep media,
  models, and backup copies on appropriately sized external storage.

## Initial install choices

- [ ] Confirm the Mac account short name is `mandubumz` before activation; the
  system and Home Manager host modules use `/Users/mandubumz`.
- [ ] Keep the initial configuration free of Homebrew and Mac App Store apps.
  Add either only when a required application is unavailable or impractical
  through Nix.
