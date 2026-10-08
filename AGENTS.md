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
  `darwinConfigurations.mandubumz-server`; system files remain under
  `hosts/mandubu-server/`, with Home Manager in
  `home/hosts/mandubumz-server.nix`. Uses the `base` and `cloud-ai-tools` profiles;
  SSH and Tailscale are enabled. The user has tested this configuration.
  Deferred Mac work is in `MAC_MIGRATION.md`.

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
  (-git, via flake input — user needs master for SystemVerilog).
- zram swap; no swap partition; no hibernation.

## TODO

- **scx_lavd scheduler retest**:
  - `services.scx` is disabled because it crashed and stalled the system during
    startup. Retest after relevant kernel or sched-ext updates; require a clean
    boot and stable session before enabling it day-to-day.
- **School profile scaffolding**:
  - Add the target-specific profile and flake output once the host details and
    requirements are known.
  - Possibly useful repo: https://github.com/krishnans2006/nixos-config/tree/main/systems/krishnan-ews
    My school environment is the same as his (EWS at UIUC).
- **Work profile scaffolding**:
  - Add the target-specific profile and flake output once the host details and
    requirements are known.
- **Applications to consider trying to make more declarative configuration for**
  - Vesktop
  - Prismlauncher

## Waiting on upstream

- **KeePassXC Wayland Auto-Type on niri**:
  - KeePassXC is declared in `home/profiles/password-manager.nix` for Daybreak
    passkeys. The user manages the Firefox extension; browser passwords and
    passkeys work without Wayland Auto-Type or desktop portals.
  - [PR #13359](https://github.com/keepassxreboot/keepassxc/pull/13359) adds
    portal-based Auto-Type in 2.8.0. As of 2026-10-08, it is in beta and pinned
    nixpkgs has 2.7.12. The current niri GNOME/GTK portal setup does not provide
    working GlobalShortcuts and RemoteDesktop support; revisit when compatible
    backends are available. [Pyrtal](https://github.com/hifi/xdg-desktop-portal-pyrtal/)
    is a suggested but unverified workaround on niri.
- **Helix Perl grammar with glibc 2.44**:
  - The `tree-sitter-perl` grammar at `72a08a49` defines `bsearch`, which
    conflicts with glibc 2.44's `_Generic` macro. Both the old and updated
    Helix inputs hit this build failure with the updated Linux nixpkgs.
  - *Status (2026-10-08)*: The updated laptop Helix input still pins the
    affected grammar revision.
  - The laptop applies `overlays/helix-perl-grammar.nix` to rename the local
    function while retaining Perl syntax support. Remove the overlay once the
    grammar fixes the conflict upstream. The Mac has an independent Helix input
    and does not use this workaround.
- **Reedline (Nushell) — Helix Normal Mode History Hint Completion**:
  - *Symptom*: Pressing `l` (or Right Arrow) on the last character in `helix_normal` mode does not complete the history autosuggestion (ghost text), unlike in `vi_normal` mode.
  - *Root Cause*: In `reedline/src/core_editor/editor.rs`, `is_cursor_at_buffer_end()` checks `!cursor.is_empty()` to avoid clobbering visual selections during hint insertion. Under Helix mode's selection-first model (`RestPolicy::BlockOverNewline`), the resting normal-mode cursor is always a 1-grapheme selection range (`anchor != head`), causing `is_cursor_at_buffer_end()` to unconditionally return `false` and reject the completion event.
  - *Upstream PR*: [nushell/reedline#1192](https://github.com/nushell/reedline/pull/1192).
  - *Status (2026-10-08)*: PR 1192 is merged and Nushell 0.116.0 has been
    released, but both hosts' pinned nixpkgs inputs still package 0.115.1,
    which predates the fix. Temporarily patched via `overlays/default.nix` +
    `overlays/reedline-1192.patch`; remove the shared overlay once both hosts'
    pinned nixpkgs inputs provide a Nushell release containing the fix.
- **Intel LPMD**:
  - Not implemented. As of 2026-10-08, the updated Linux nixpkgs pin has
    neither an `intel-lpmd` package nor a `services.intel-lpmd` option.
  - The AC/battery watcher omits the old `intel_lpmd_control` calls. Revisit if
    upstream packaging lands or maintaining a custom package and service
    becomes worthwhile.
- **NVIDIA open driver — battery NVPCF D0 wakeups**:
  - *Symptom*: On battery, each 1% charge drop wakes the otherwise idle dGPU
    from D3cold to D0 for about 22.6 seconds. Reproduced twice on this GU605MI;
    it matches the independent GU605 report in
    [discussion #1201](https://github.com/NVIDIA/open-gpu-kernel-modules/discussions/1201).
  - *Working Root Cause*: The firmware emits an ACPI NVPCF notification at each
    battery percentage change, and the open driver's handler takes a runtime-PM
    reference even while the GPU is suspended.
  - *Upstream PR*: [NVIDIA/open-gpu-kernel-modules#1299](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1299).
  - *Status (2026-10-08)*: PR 1299 is still open; the updated Linux pin uses
    stable driver 595.104.02. Temporarily patched by
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

- Update Linux inputs with `nix flake update nixpkgs nixos-hardware home-manager lanzaboote helix noctalia noctalia-greeter gaze`.
  Update Mac inputs with `nix flake update nixpkgs-darwin nix-darwin home-manager-darwin helix-darwin nix-plist-manager`.
  Home Manager and Helix have separate inputs for each host; keep their
  `nixpkgs` follows pointed at the matching host input.
- **Never write a NixOS/home-manager option or package name from memory.**
  Verify via mcp-nixos tools (`mcp__nixos__nix`, search/info actions) or
  `nix search`. **Always do this even if the user provides the package name.** Wrong-but-plausible option names are the #1 failure mode.
- Validation ladder (no root needed):
  1. **Format your code**: Run `nix fmt` *before* validating to ensure clean Nix code.
  2. `nix flake check` — catches evaluation errors; on Linux it omits the
     incompatible Darwin system.
  3. Build the affected system: for NixOS,
     `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`;
     for nix-darwin, build on the Mac. A real build catches what evaluation
     does not.
  Then apply on the target machine with the appropriate rebuild command (user
  runs sudo).
  `build-vm` is NOT part of the regular flow — it's a backup debugging tool to
  separate "config bug" from "hardware bug" if a boot issue appears.
- Don't pipe validation commands through `tail`/`head` before `&&` — the
  pipe masks the exit code. Run them bare or with `set -o pipefail`.
- Bulk module-writing goes to the `nix-module-writer` subagent (using a lightweight model) to
  save usage and context; planning/review/decisions stay with the lead model.
- The deal with the user: they manage at a high level; bring them decisions
  (especially boot/filesystem/kernel-adjacent), not minutiae. Commit early
  and often.
- `inventory/`, `MAPPING.md`, and the archived migration checklist are
  historical references. They are not imported or regenerated; consult them
  only when a past decision needs context.

## Repo layout

```
flake.nix                 # NixOS/Darwin outputs, inputs, checks, formatters
flake.lock                # pinned inputs, including Darwin-specific nixpkgs
hosts/home-g16/           # NixOS host, hardware, boot, and performance
hosts/mandubu-server/     # nix-darwin host module
modules/nixos/            # shared NixOS system modules
home/common/              # shared Home Manager modules and assets
home/profiles/            # reusable capability bundles
home/hosts/               # identity, profile selection, host-only modules
overlays/                 # package overrides shared by both outputs
pkgs/                     # custom packages not in nixpkgs
MAC_MIGRATION.md          # deferred macOS profiles and operational concerns
inventory/                # captured Arch system state (historical reference)
```

- One concern per module. Home host files compose reusable profiles and may
  also import host-only modules such as laptop power or monitoring services.
  A hardware-aware module is not a reusable profile.
- Home identity (`home.username` and `home.homeDirectory`) and machine-specific
  paths, displays, and hardware bindings live in `home/hosts/<host>.nix` or its
  companion directory. Profiles must remain usable from standalone
  home-manager on foreign distributions.
- System hosts live in `hosts/`. NixOS hosts compose shared `modules/nixos/`
  modules; machine-specific config stays with the host (for example,
  `hosts/home-g16/hardware.nix`). The Darwin host currently has its own small
  module in `hosts/mandubu-server/default.nix`.
- Prefer native NixOS/nix-darwin/Home Manager options over raw dotfiles; use
  `xdg.configFile` to ship verbatim configs only when no module exists.
- Comment-light, idiomatic Nix; pin nothing without a reason.
