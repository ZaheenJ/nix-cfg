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

The router listens only on the Mac's loopback interface. On home-g16, run `pi`
from the project directory. Its wrapper starts the `pi-llama-tunnel` user service
on demand. SSH forwards the router to a private Unix socket, which Pi reaches
at `127.0.0.1:8080` inside its Bubblewrap network namespace. Pi cannot make
other direct network connections. If the tunnel or router is unavailable, check
`systemctl --user status pi-llama-tunnel` and
`journalctl --user -u pi-llama-tunnel`. `/model` selects a loaded model, and
`/llama` can load and unload models. Its download search needs direct
Hugging Face access and therefore does not work inside this sandbox. Download
new models on the Mac instead, for example with a router request from the Mac:

```sh
curl -X POST http://127.0.0.1:8080/models \
  -H 'Content-Type: application/json' \
  -d '{"model":"REPOSITORY:QUANTIZATION"}'
```

The router starts without a model. Its presets use 32K context for
`byteshape/Qwen3.8-27B-GGUF:IQ4_XS` and
`unsloth/Qwen3.8-27B-GGUF:IQ4_XS`, 131K for
`unsloth/Qwen3.5-9B-GGUF:Q5_K_M`, and 32K for other models. The initial model
directory is `/Users/mandubumz/models` pending the external-storage decision;
router downloads live in llama.cpp's cache instead. The short Byteshape alias
points to a specific GGUF in the Hugging Face cache, so preserve that snapshot
or update its preset path if the cache is cleaned. Switching models does not
require deleting the old downloads; remove them only to reclaim disk space.
The 27B presets use non-mapped loading, flash attention, and Q8 K/V cache;
llama.cpp chooses the GPU layer count to fit available memory. The boot
daemon sets the wired GPU memory limit to 85% of this Mac's 18 GiB, and the
router skips vision projectors because only text is needed.

The 2026-10-03 no-MTP, text-only 27B run loaded all 66/66 layers on Metal.
The server allocated 12,726 MiB of GPU model buffers, 1,088 MiB of Q8 KV
cache at 32K context, 269 MiB of GPU compute buffers, and 573 MiB of CPU
model/compute buffers. Across five completions, it generated 4,129 tokens at
8.09 tokens/s. While the model ran, system free memory fell to 4–8%, and
system-wide swapouts increased by 1,646 MiB. The server created 11 context
checkpoints of 149.626 MiB each (about 1,646 MiB total), with no checkpoint
evictions in the log. The separate host-RAM prompt cache reported 0 MiB used
and had no save events. The checkpoint growth plausibly explains much of the
new swap pressure, but system-wide swap counters cannot attribute pages to a
specific allocation.

Both 27B presets disable the separate host-RAM prompt cache and cap context
checkpoints at four. The Unsloth MTP trial generated about 6.3–6.5 tokens/s,
versus about 8.1 tokens/s without it; the Byteshape preset is currently also
configured without MTP. Limiting checkpoints reduces memory used as the
conversation grows, but does not remove the separate draft context that MTP
creates when the model loads.

Other llama.cpp tuning after this run:

- Keep automatic GPU fitting with its default 1024 MiB target: all layers fit,
  so there is no reason to force more GPU offload.
- `ctx-checkpoints` defaults to 32 per slot. The new cap of 4 limits snapshots
  to about 599 MiB at the observed checkpoint size, instead of the 1,646 MiB
  reached here. Fewer checkpoints may require more prompt reprocessing when Pi
  revises an earlier part of a conversation.
- `cache-ram` defaults to an 8192 MiB *limit*, not a reservation. Reducing it
  alone would not have prevented this run's swap, because no separate prompt
  entries were saved. It is now 0 for the 27B preset. If
  interrupted-conversation reuse proves useful, test at most 512 MiB. Keep
  `cache-prompt` enabled for in-slot prefix reuse. An 8 GiB cache actually
  filled on this Mac would create severe memory pressure.
- `--no-webui` is optional for a Pi-only server and should save little memory
  or compute. Embeddings, reranking, metrics, and built-in server tools are
  already disabled by default. `--sleep-idle-seconds` would free model and KV
  memory while idle, but the next request would have to reload the model.
- The 9B preset still uses default F16 K/V cache and automatic flash attention
  at 131K context. Benchmark Q8 K/V and explicit flash attention if that long
  context becomes a regular workload.

The home-g16 client builds `billion-context` and `rpiv-ask-user-question` from
`pkgs/pi-extensions/package.json` and its integrity-locked
`package-lock.json`. To change packages, edit the manifest and regenerate the
lockfile in a normal networked shell (`npm install --package-lock-only
--legacy-peer-deps` from `pkgs/pi-extensions`), then rebuild. Pi's own package
install, update, remove, and config commands are disabled by the wrapper.
`/acp` shows `billion-context` status. Pi defaults to the Byteshape 27B model
at `xhigh` thinking when loaded. Both 27B aliases offer off, low, medium, and
xhigh thinking and use 8K compaction reserves for their 32K context. The 9B
model defaults to thinking on. These Pi settings and model overrides are
declarative; change them in Nix, then rebuild. Pi's `/thinking` still changes
the level for the current session.

Pi sees only the current project directory writable at a stable `/workspace`
path, its private state, and a private `/tmp` backed by a per-run directory
under `/tmp/pi`. The state starts fresh at `~/.local/state/pi-sandbox`; the old
`~/.pi/agent` is left untouched. Pi has read-only access to the Nix store and
necessary Linux runtime paths, but not the host's SSH agent or Nix daemon.
The current directory itself is writable, so launch Pi from a project rather
than `~` if the rest of the home directory must stay protected. The router API
is the one intentional external service and can initiate downloads on the Mac.

## Initial install choices

- [ ] Keep the initial configuration free of Homebrew and Mac App Store apps.
  Add either only when a required application is unavailable or impractical
  through Nix.
