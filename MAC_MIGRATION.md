# macOS migration checklist

## Deferred configuration

- [ ] Port the custom fish Helix key bindings. They currently use Linux-oriented
  `sed -z` and `xsel`; macOS uses fish vi bindings until this is adapted.
- [ ] Adapt the Helix `C-z` PDF helper, which currently calls `xdg-open`. Use
  macOS `open` or Preview when revisiting it. Zathura is not required for this
  helper.
- [ ] Review `desktop-agnostic.nix` before importing it. XDG config paths work
  on macOS, but Home Manager's `xdg.mimeApps` support is Linux-only.
- [ ] Review the remaining profiles before adding them: `cli-extras`,
  `browser-extras`, `communications`, `media`, `music`,
  `gaming`, `personal-sync`, and `niri-desktop`.
- [ ] Port or replace the host-specific Niri, Noctalia, power, monitoring, and
  display configuration. These are currently Linux desktop/laptop concerns.
- [x] Declare the local AI llama.cpp router as a system `launchd` daemon and
  install Pi on home-g16.
- [ ] Verify that the local AI daemon serves requests and uses Metal before
  user login. If Metal inference fails in the system context, move it to a
  login-time agent. FileVault must unlock the disk before the daemon can start;
  macOS still boots its graphical login environment.
- [ ] Add Jellyfin and Minecraft service configuration after evaluating macOS
  support, resource use, and service lifecycle needs.
- [ ] Design sync and backup separately. Syncthing can synchronize files, but
  a separate versioned backup is needed to recover deleted or changed data.
- [x] Configure keyboard repeat rate and delay until repeat
- [x] Map Caps Lock to Escape, including after login
- [ ] Declare/verify keyboard layout like Linux (macOS currently uses U.S.)
- [ ] Configure both Shift keys to toggle Caps Lock like Linux
- [x] Add Tailscale/SSH for remote access
- [ ] Use duti to set default apps
- [x] Configure Touch ID for sudo

## MacBook operation and storage

- [ ] Decide how the MacBook should stay awake with its lid closed when it is
  serving requests, including whether this should apply only on power and/or
  while connected to a network.
- [ ] Plan external storage: the roughly 500 GB internal drive is shared by
  macOS, Nix, applications, media, local AI models, and backups. Keep media,
  models, and backup copies on appropriately sized external storage.

## Local AI operation

The router listens only on the Mac's loopback interface. On home-g16, start
`ssh -N -L 8080:127.0.0.1:8080 mandu`, then run `pi`. Pi's `/llama` command
downloads, loads, and unloads models on the Mac; `/model` selects a loaded model.
The router starts without a model and limits context to 128K tokens per model.
Change that server setting, or add llama.cpp model presets, to use a different
context size. The initial model directory is `/Users/mandubumz/models` pending
the external-storage decision.

The home-g16 client profile pins `billion-context` as a Pi package. Pi installs
it on first launch after a rebuild; `/acp` shows its status. It compresses Pi's
conversation history but does not change the router's context limit.

## Initial install choices

- [ ] Keep the initial configuration free of Homebrew and Mac App Store apps.
  Add either only when a required application is unavailable or impractical
  through Nix.
