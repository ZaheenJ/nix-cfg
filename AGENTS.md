# NixOS Flake Config

Multi-host NixOS flake (home-manager as NixOS module). The personal laptop
(**home-g16**) runs this config day-to-day. Shared `home/` modules stay
distro-agnostic so future profiles can use standalone home-manager on foreign
distros. Modeled on https://nixos-and-flakes.thiscute.world/.

Day-to-day changes are applied on the machine with
`sudo nixos-rebuild switch --flake ~/nix#home-g16` (user runs the sudo).

## Hard facts about the personal machine

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

- **Reedline (Nushell) — Helix Normal Mode History Hint Completion**:
  - *Symptom*: Pressing `l` (or Right Arrow) on the last character in `helix_normal` mode does not complete the history autosuggestion (ghost text), unlike in `vi_normal` mode.
  - *Root Cause*: In `reedline/src/core_editor/editor.rs`, `is_cursor_at_buffer_end()` checks `!cursor.is_empty()` to avoid clobbering visual selections during hint insertion. Under Helix mode's selection-first model (`RestPolicy::BlockOverNewline`), the resting normal-mode cursor is always a 1-grapheme selection range (`anchor != head`), causing `is_cursor_at_buffer_end()` to unconditionally return `false` and reject the completion event.
  - *Upstream PR*: [nushell/reedline#1192](https://github.com/nushell/reedline/pull/1192).
  - *Status*: PR 1192 is merged. Nushell 0.115.1 is the latest release and the
    current nixpkgs package, but it predates the merge. Nushell main declares
    version 0.115.2 and pins a Reedline revision containing the fix. Temporarily
    patched via `overlays/default.nix` + `overlays/reedline-1192.patch`; remove
    the overlay once nixpkgs provides Nushell >= 0.115.2.
- **Intel LPMD**:
  - Not implemented. As of 2026-09-08, nixpkgs-unstable has neither an
    `intel-lpmd` package nor a `services.intel-lpmd` option.
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
  - *Status*: Temporarily patched by `overlays/nvidia-nvpcf-1299.nix`. The
    override follows nixpkgs' unpinned stable driver and should be removed once
    the PR is released upstream. An incompatible or already-applied patch will
    intentionally fail the build rather than silently losing the workaround.

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

- **Never write a NixOS/home-manager option or package name from memory.**
  Verify via mcp-nixos tools (`mcp__nixos__nix`, search/info actions) or
  `nix search`. **Always do this even if the user provides the package name.** Wrong-but-plausible option names are the #1 failure mode.
- Validation ladder (no root needed):
  1. **Format your code**: Run `nix fmt` *before* validating to ensure clean Nix code.
  2. `nix flake check` — seconds, catches evaluation errors
  3. `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
     — the real build; catches what eval doesn't (flake check is not enough).
  Then apply with `sudo nixos-rebuild switch --flake .#<host>` (user runs).
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
flake.nix            # inputs: nixpkgs, home-manager, lanzaboote, helix,
                     #         noctalia, noctalia-greeter (niri via nixpkgs)
hosts/<host>/        # default.nix + hardware-configuration.nix per machine
modules/nixos/       # shared system modules (core, boot, desktop-niri, gaming, ...)
home/common/         # atomic, distro-agnostic home-manager modules and assets
home/profiles/       # reusable capability bundles (base, music, desktop, ...)
home/hosts/          # user identity, profile selection, and host-only modules
overlays/            # package overrides
pkgs/                # custom packages not in nixpkgs
inventory/           # captured Arch system state (historical reference)
```

- One concern per module. Home host files compose reusable profiles and may
  also import host-only modules such as laptop power or monitoring services.
  A hardware-aware module is not a reusable profile.
- Home identity (`home.username` and `home.homeDirectory`) and machine-specific
  paths, displays, and hardware bindings live in `home/hosts/<host>.nix` or its
  companion directory. Profiles must remain usable from standalone
  home-manager on foreign distributions.
- NixOS hosts compose system modules + set host-specific options.
  Machine-specific config lives with the host (hosts/home-g16/hardware.nix),
  so modules/nixos/ stays host-agnostic.
- Prefer native NixOS/home-manager options over raw dotfiles; use
  `xdg.configFile` to ship verbatim configs only when no module exists.
- Comment-light, idiomatic Nix; pin nothing without a reason.
