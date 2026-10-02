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
The router starts without a model. Its presets use 32K context for
`unsloth/Qwen3.8-27B-GGUF:IQ4_XS`, 131K for
`unsloth/Qwen3.5-9B-GGUF:Q5_K_M`, and 32K for other models. The initial model
directory is `/Users/mandubumz/models` pending the external-storage decision;
models downloaded through `/llama` live in llama.cpp's cache instead. Switching
models does not require deleting the old downloads; remove them only to reclaim
disk space. The 27B preset uses non-mapped loading and 48 GPU layers because
ordinary Metal loading exhausted this Mac's working set even at 32K context.

The home-g16 client profile pins `billion-context` and
`rpiv-ask-user-question` as Pi packages. Pi installs them on first launch after
a rebuild; `/acp` shows the former's status. Pi defaults to the 27B model at
`xhigh` thinking when loaded and uses 8K compaction reserves for its 32K
context. The 9B model defaults to thinking on. These Pi settings and model
overrides are declarative; change them in Nix, then rebuild. Pi's `/thinking`
still changes the level for the current session.

## Initial install choices

- [ ] Keep the initial configuration free of Homebrew and Mac App Store apps.
  Add either only when a required application is unavailable or impractical
  through Nix.
