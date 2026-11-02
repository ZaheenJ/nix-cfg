# NixOS and nix-darwin Flake Config

Multi-host flake with NixOS and nix-darwin outputs. Home Manager is integrated
as a module in each system. Shared `home/` modules stay distro-agnostic so
future profiles can use standalone Home Manager on foreign distros. Modeled on
https://nixos-and-flakes.thiscute.world/.

Day-to-day changes to home-g16 are applied on that machine with
`sudo nixos-rebuild switch --flake ~/nix#home-g16` (user runs the sudo).

## Configurations

- **home-g16**: ASUS ROG Zephyrus G16 personal laptop, `x86_64-linux` NixOS.
  Flake output: `nixosConfigurations.home-g16`. System files:
  `hosts/home-g16/`; Home Manager host: `home/hosts/home-g16.nix`.
- **mandubumz-server**: M3 Pro MacBook, 18 GB RAM, roughly 500 GB internal
  storage, `aarch64-darwin`. Flake output:
  `darwinConfigurations.mandubumz-server`; system files live under
  `hosts/mandubumz-server/`, with Home Manager in
  `home/hosts/mandubumz-server.nix`. Uses the `base` and `cloud-ai-tools` profiles;
  SSH and Tailscale are enabled. The user has tested this configuration.

## Hard facts about home-g16

- ASUS ROG Zephyrus G16 (GU605MI): Intel Core Ultra 9 185H (Meteor Lake, Intel
  Arc iGPU) + NVIDIA RTX 4070 Max-Q **hybrid graphics**, 16 GB RAM, Intel CNVi
  WiFi. Uses the nixos-hardware `asus-zephyrus-gu605my` profile (GU605MY = 4090
  vs our 4070, same Ada platform). Drivers: nvidia **open** module, prime
  offload, `powerManagement.finegrained` (runtime D3 gating). Face auth uses
  **Gaze** with the IR camera; its emitter is hardware-controlled, so
  `linux-enable-ir-emitter` is intentionally absent.
- **Secure Boot is ENABLED** with personal sbctl keys (+ Microsoft vendor keys).
  Boot signing is **lanzaboote**, using the sbctl keys at `/var/lib/sbctl`.
- Bootloader: **systemd-boot via lanzaboote**, the SOLE bootloader (rEFInd was
  removed). It lives on the **shared ESP** `/dev/nvme0n1p1` (vfat at `/boot`,
  only ~930 MB free, shared with Windows on p3 + Arch/CachyOS on p7). Keep
  lanzaboote `configurationLimit` low (≤5) — ESP space is the binding
  constraint. **Never let NixOS reformat the ESP**, and never run
  `bootctl install` (it would overwrite the signed systemd-boot). Windows is
  auto-detected; the Arch/CachyOS entry is hand-shipped as `arch.conf` via
  tmpfiles (see hosts/home-g16/boot.nix).
- NixOS partition: `/dev/nvme0n1p8`, btrfs, label `NixOS`, UUID
  `1198bc8f-1186-44a5-aed4-e9a0bbb80ab6`, subvolumes `@ @home @nix @log`.
  Arch lives on p7 (don't touch), Windows on p3.
- Mount options (user prefers performance): `noatime,compress=zstd:1,commit=120`.
- Desktop stack: **niri** (wayland, scrollable tiling) + **noctalia** shell +
  xwayland-satellite + vicinae launcher, pipewire audio. Login is **greetd +
  noctalia-greeter** (password login); pam_gnome_keyring unlocks the login
  keyring on auth. Gaze is enabled for the short-lived `sudo`, `login`, and
  `polkit-1` PAM consumers, but deliberately excluded from `greetd` so face
  auth cannot bypass the password needed to unlock the GNOME login keyring.
- Shells: **fish** is the login shell; **nushell** is the primary interactive
  shell (ghostty starts it). Plus starship, carapace, zoxide. Editor: **helix**
  (gj1118's fork, via separate flake inputs for Linux and Darwin, for code
  folding, inline blame, and popup UI; retains SystemVerilog support).
- zram swap; no swap partition; no hibernation.

## TODO

- **scx_lavd scheduler retest**:
  - `services.scx` is disabled because it crashed and stalled the system during
    startup. Retest after relevant kernel or sched-ext updates; require a clean
    boot and stable session before enabling it day-to-day.
- **Intel LPMD evaluation**:
  - As of 2026-11-01, the Linux pin includes `intel-lpmd`
    `0.1.0-unstable-2026-09-23` and a native `services.intel-lpmd` module.
    Packaging is no longer an upstream blocker.
  - Leave it disabled until its interaction with power-profiles-daemon and
    this laptop's battery/performance policy has been evaluated. The
    AC/battery watcher still omits the old `intel_lpmd_control` calls.
- **School profile scaffolding**:
  - Add the target-specific profile and flake output once the host details and
    requirements are known.
  - Possibly useful repo: https://github.com/krishnans2006/nixos-config/tree/main/systems/krishnan-ews
    My school environment is the same as his (EWS at UIUC).
- **Work profile scaffolding**:
  - Add the target-specific profile and flake output once the host details and
    requirements are known.
- **Applications to consider trying to make more declarative configuration for**
  - Prismlauncher

## Waiting on upstream

- **Serein — NVIDIA wake from media discovery**:
  - On 2026-10-18, GStreamer VA-API discovery reproduced a sustained NVIDIA
    `D0` state with runtime usage `1`, even without video playback. Forcing
    Intel's `iHD` driver allowed runtime suspend after the initial probing wake;
    the user confirmed `LIBVA_DRIVER_NAME=iHD` alone fixes Serein too.
  - `home/hosts/home-g16/serein.nix` wraps only the laptop's Serein package;
    `local.serein.package` keeps terminal, niri, and desktop/URL launches aligned.
    Remove the workaround once an upstream fix is verified on this laptop.
  - *Status (2026-11-02)*: Serein `5aa2e486` and the complete Linux system
    built successfully with the original optimization settings after freeing
    RAM. No unwrapped startup/media power test on this laptop has verified a
    fix. Keep the Intel-only wrapper until that hardware check passes.

- **Pi output budget after Billion Context compression**:
  - Pi sizes output from stale pre-compression usage. On 2026-10-09, it
    allowed only 3,312 output tokens despite the compressed request containing
    21,663 input tokens in a 65,536-token context window.
  - `pkgs/pi-extensions/patch-output-budget.mjs` patches Billion Context
    0.1.178 for the laptop's Qwen ASCII model only. Native pi main requests
    restore the advertised output ceiling before the proxy's compressed-input
    clamp; other models, side requests, and direct fallback remain unchanged.
  - The package build fails if the pinned patch point changes. Remove the
    workaround once upstream repairs client-shrunk budgets above 200 tokens,
    then retain the regression coverage. Compression still happens between
    model requests, not inside uninterrupted thinking generation.
  - *Status (2026-11-01)*: Updated Pi 1.4.0 still reproduces the 3,312-token
    client-side clamp using stale usage. Published Billion Context 0.1.211
    still restores budgets above 200 only for the Dsh lane. A probe of its
    actual published `restoreOutputBudget` left a native Pi budget of 3,312 unchanged despite
    a known 65,536 ceiling. Retain the patched 0.1.178 pin and regression tests.
    Audited source: [0.1.211 commit](https://github.com/ranxianglei/billion-context/tree/e226544f556712e33f3ef1d9fe5b4dc2b7715e15).

- **KeePassXC Wayland Auto-Type on niri**:
  - KeePassXC is declared in `home/profiles/password-manager.nix` for Daybreak
    passkeys. The user manages the Firefox extension; browser passwords and
    passkeys work without Wayland Auto-Type or desktop portals.
  - [PR #13359](https://github.com/keepassxreboot/keepassxc/pull/13359) shipped
    portal-based Auto-Type in [2.8.0](https://github.com/keepassxreboot/keepassxc/releases/tag/2.8.0).
    As of 2026-11-01, that release is available upstream but the updated Linux
    pin still packages 2.7.12. The current niri GNOME/GTK portal setup has no
    verified working GlobalShortcuts and RemoteDesktop support; revisit both
    packaging and compatible backends. [Pyrtal](https://github.com/hifi/xdg-desktop-portal-pyrtal/)
    remains an unverified workaround on niri.
- **Reedline (Nushell) — Helix Normal Mode History Hint Completion**:
  - *Symptom*: Pressing `l` (or Right Arrow) on the last character in `helix_normal` mode does not complete the history autosuggestion (ghost text), unlike in `vi_normal` mode.
  - *Root Cause*: In `reedline/src/core_editor/editor.rs`, `is_cursor_at_buffer_end()` checks `!cursor.is_empty()` to avoid clobbering visual selections during hint insertion. Under Helix mode's selection-first model (`RestPolicy::BlockOverNewline`), the resting normal-mode cursor is always a 1-grapheme selection range (`anchor != head`), causing `is_cursor_at_buffer_end()` to unconditionally return `false` and reject the completion event.
  - *Upstream PR*: [nushell/reedline#1192](https://github.com/nushell/reedline/pull/1192).
  - *Status (2026-11-01)*: PR 1192 is merged. The updated Linux pin provides
    Nushell 0.116.1, which includes the fix; the unchanged Mac pin still has
    0.115.1. `overlays/default.nix` now applies `overlays/reedline-1192.patch`
    only below 0.116.0, so Linux uses upstream Nushell and the Mac keeps its
    workaround. Remove the overlay and patch once the Mac pin catches up.
- **NVIDIA open driver — battery NVPCF D0 wakeups**:
  - *Symptom*: On battery, each 1% charge drop wakes the otherwise idle dGPU
    from D3cold to D0 for about 22.6 seconds. Reproduced twice on this GU605MI;
    it matches the independent GU605 report in
    [discussion #1201](https://github.com/NVIDIA/open-gpu-kernel-modules/discussions/1201).
  - *Working Root Cause*: The firmware emits an ACPI NVPCF notification at each
    battery percentage change, and the open driver's handler takes a runtime-PM
    reference even while the GPU is suspended.
  - *Upstream PR*: [NVIDIA/open-gpu-kernel-modules#1299](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1299).
  - *Status (2026-11-01)*: PR 1299 is still open; the updated Linux pin uses
    stable driver 595.112.07. Temporarily patched by
    `overlays/nvidia-nvpcf-1299.nix`. The override follows nixpkgs' unpinned
    stable driver and should be removed once the PR is released upstream. An
    incompatible or already-applied patch will intentionally fail the build
    rather than silently losing the workaround.

## User preferences (load-bearing)

- Vanilla kernel/`linuxPackages`, NOT CachyOS variants. Standard Proton, not
  proton-cachyos (gaming via `programs.steam`; proton-ge-bin optional).
- Performance over conservative defaults (mount flags, zram, scx_lavd, etc.).
- No Determinate Systems installer/tooling — upstream Nix only.
- User approves all sudo personally. **sudo does not work in non-interactive agent shells**
  (no TTY for password) — ask the user to run sudo commands directly.
- Implement idiomatic nix patterns, and notify the user of
  any anti-patterns if strictly necessary.
- Never change system.stateVersion or home.stateVersion
- Never hardcode secrets, prompt user for how to handle secrets

## Workflow rules

- Update Linux inputs with `nix flake update nixpkgs nixos-hardware home-manager lanzaboote helix noctalia noctalia-greeter gaze serein`.
  Update Mac inputs with `nix flake update nixpkgs-darwin nix-darwin home-manager-darwin helix-darwin nix-plist-manager`.
  Home Manager and Helix have separate inputs for each host; keep their
  `nixpkgs` follows pointed at the matching host input.
- **Never write a NixOS/home-manager option or package name from memory.**
  Verify via mcp-nixos tools (`mcp__nixos__nix`, search/info actions) or
  `nix search`. **Always do this even if the user provides the package name.** Wrong-but-plausible option names are the #1 failure mode.
- Validation ladder (no root needed):
  1. **Format your code**: Run `nix fmt` *before* validating to ensure clean Nix code.
  2. `nix flake check` — catches evaluation errors and runs the native checks.
     Both platforms check shell syntax and AI settings merges; Linux also
     checks the Pi output-budget patch. Run on each host to cover its pin.
  3. Build the affected system: for NixOS,
     `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`;
     for nix-darwin, run
     `nix build .#darwinConfigurations.mandubumz-server.system` on the Mac.
     A real build catches what evaluation does not.
  Then apply on the target machine with the appropriate rebuild command (user
  runs sudo).
  `build-vm` is NOT part of the regular flow — it's a backup debugging tool to
  separate "config bug" from "hardware bug" if a boot issue appears.
- For memory-constrained updates, stage large uncached packages before the
  complete system build to reduce evaluation-memory overhead. Keep earlyoom
  enabled; Serein's fat-LTO build may require closing Firefox.
- Don't pipe validation commands through `tail`/`head` before `&&` — the
  pipe masks the exit code. Run them bare or with `set -o pipefail`.
- Bulk module-writing goes to the `nix-module-writer` subagent (using a lightweight model) to
  save usage and context; planning/review/decisions stay with the lead model.
- The deal with the user: they manage at a high level; bring them decisions
  (especially boot/filesystem/kernel-adjacent), not minutiae. Commit early
  and often.
- `inventory/` is historical reference. It is not imported or regenerated;
  consult it only when a past decision needs context.

## Repo layout

```
flake.nix                 # NixOS/Darwin outputs, inputs, check wiring, formatters
flake.lock                # pinned inputs, including Darwin-specific nixpkgs
checks/default.nix        # native checks using each host's configured packages
hosts/home-g16/           # NixOS host, hardware, boot, and performance
hosts/mandubumz-server/   # nix-darwin host modules
modules/nixos/            # shared core, desktop, and capability modules
home/common/              # shared Home Manager modules and assets
home/profiles/            # reusable capability bundles
home/hosts/               # identity, profile selection, host-only modules
overlays/                 # package overrides shared by both outputs
pkgs/                     # custom packages not in nixpkgs
inventory/                # captured Arch system state (historical reference)
```

- One concern per module. Home host files compose reusable profiles and may
  also import host-only modules such as laptop power or monitoring services.
  A hardware-aware module is not a reusable profile.
- Home identity (`home.username` and `home.homeDirectory`) and machine-specific
  paths, displays, and hardware bindings live in `home/hosts/<host>.nix` or its
  companion directory. Profiles must remain usable from standalone
  home-manager on foreign distributions.
- General niri keybindings live in
  `home/profiles/niri-desktop/niri/keybindings.nix`, imported by `niri.nix`.
  The laptop's outer Pi wrapper lives in `home/hosts/home-g16/pi-sandbox/pi.sh`;
  `pi-sandbox.nix` supplies paths and dependencies and retains the short inner
  wrapper and service configuration.
- System hosts live in `hosts/`. NixOS hosts compose shared `modules/nixos/`
  modules; machine-specific config stays with the host (for example,
  `hosts/home-g16/hardware.nix`). The Darwin host currently has its own small
  module in `hosts/mandubumz-server/default.nix`.
- `modules/nixos/core.nix` owns base system defaults; `desktop.nix` owns
  compositor-independent desktop services; `desktop-niri.nix` owns the niri
  login and desktop integration. Hosts select these explicitly. Personal
  accounts and peripheral rules belong to the host modules.
- Prefer native NixOS/nix-darwin/Home Manager options over raw dotfiles; use
  `xdg.configFile` to ship verbatim configs only when no module exists.
- Comment-light, idiomatic Nix; pin nothing without a reason.
- Check implementations live in `checks/default.nix`; the flake supplies each
  host's configured package set (including overlays) and the Linux Pi package
  directory. The hardware input follows the Linux nixpkgs pin.
