# NixOS Flake Config

Multi-host NixOS flake (home-manager as NixOS module). The personal laptop
(**home-g16**) runs this config day-to-day; school and work hosts will be
scaffolded later (some home-manager-only on foreign distros, so `home/` modules
stay distro-agnostic). Modeled on https://nixos-and-flakes.thiscute.world/.

Day-to-day changes are applied on the machine with
`sudo nixos-rebuild switch --flake ~/nix#home-g16` (user runs the sudo).

## Hard facts about the personal machine

- ASUS ROG Zephyrus G16 (GU605MI): Intel Core Ultra 9 185H (Meteor Lake, Intel
  Arc iGPU) + NVIDIA RTX 4070 Max-Q **hybrid graphics**, 16 GB RAM, Intel CNVi
  WiFi. Uses the nixos-hardware `asus-zephyrus-gu605my` profile (GU605MY = 4090
  vs our 4070, same Ada platform). Drivers: nvidia **open** module, prime
  offload, `powerManagement.finegrained` (runtime D3 gating). Face auth via
  **howdy** (IR camera, control=sufficient) + linux-enable-ir-emitter.
- **Secure Boot is ENABLED** with personal sbctl keys (+ Microsoft vendor keys).
  Boot signing is **lanzaboote**, using the sbctl keys at `/var/lib/sbctl`.
- Bootloader: **systemd-boot via lanzaboote**, the SOLE bootloader (rEFInd was
  removed). It lives on the **shared ESP** `/dev/nvme0n1p1` (vfat at `/boot`,
  only ~930 MB free, shared with Windows on p3 + Arch/CachyOS on p7). Keep
  lanzaboote `configurationLimit` low (≤5) — ESP space is the binding
  constraint. **Never let NixOS reformat the ESP**, and never run
  `bootctl install` (it would overwrite the signed systemd-boot). Windows is
  auto-detected; the Arch/CachyOS entry is hand-shipped as `arch.conf` via
  tmpfiles (see hosts/home-g16/hardware.nix).
- NixOS partition: `/dev/nvme0n1p8`, btrfs, label `NixOS`, UUID
  `1198bc8f-1186-44a5-aed4-e9a0bbb80ab6`, subvolumes `@ @home @nix @log`.
  Arch lives on p7 (don't touch), Windows on p3.
- Mount options (user prefers performance): `noatime,compress=zstd:1,commit=120`.
- Desktop stack: **niri** (wayland, scrollable tiling) + **noctalia** shell +
  xwayland-satellite + vicinae launcher, pipewire audio. Login is **greetd +
  noctalia-greeter** (password login); pam_gnome_keyring unlocks the login
  keyring on auth. (howdy is disabled for the `polkit-1` PAM service only — it
  breaks GUI polkit auth in-session.)
- Shells: **fish** is the login shell; **nushell** is the primary interactive
  shell (ghostty starts it). Plus starship, carapace, zoxide. Editor: **helix**
  (-git, via flake input — user needs master for SystemVerilog).
- zram swap; no swap partition; no hibernation.
- **Face auth (gaze) must NOT be wired into long-lived PAM consumers.**
  `pam_gaze.so` runs the recognizer in-process and leaves ~2.8 GB of **mlock'd**
  per-CPU inference buffers (22 × 128 MB on this 22-thread CPU) that it never
  frees/munlocks after auth. In a short-lived auth process (sudo/polkit-1/login)
  that's transient; in **greetd's session-worker**, which lives for the whole
  login session, it becomes a permanent 2.8 GB unswappable mlock — the main
  driver of the 2026-07 memory-freeze. So gaze is enabled for sudo/polkit-1/login
  but **deliberately not greetd** (services.gaze.pamServices in
  hosts/home-g16/hardware.nix). Note the mlock: this RAM can't be swapped to zram
  or reclaimed, and earlyoom keys on free RAM, so nothing catches it — the only
  fix is to not create it. (Upstream gaze bug: the module should free/munlock on
  pam_end.) More generally on this 22-thread box, suspect any threaded service
  idling at a round multiple of ~128 MB — glibc malloc-arena bloat is the usual
  culprit there, tunable with `MALLOC_ARENA_MAX` / `GLIBC_TUNABLES`.

## User preferences (load-bearing)

- Vanilla kernel/`linuxPackages`, NOT CachyOS variants. Standard Proton, not
  proton-cachyos (gaming via `programs.steam`; proton-ge-bin optional).
- Performance over conservative defaults (mount flags, zram, scx_lavd, etc.).
- No Determinate Systems installer/tooling — upstream Nix only.
- User approves all sudo personally. **sudo does not work in non-interactive agent shells**
  (no TTY for password) — ask the user to run sudo commands directly.

## Workflow rules

- **Never write a NixOS/home-manager option or package name from memory.**
  Verify via mcp-nixos tools (`mcp__nixos__nix`, search/info actions) or
  `nix search`. Wrong-but-plausible option names are the #1 failure mode.
- Validation ladder (no root needed):
  1. `nix flake check` — seconds, catches evaluation errors
  2. `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
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
- `inventory/` and `OLD_MIGRATION_PLAN.md` are historical reference from the
  CachyOS→NixOS migration (captured Arch state + the completed plan). Not
  imported, not regenerated — consult only when a past decision needs context.

## Repo layout

```
flake.nix            # inputs: nixpkgs, home-manager, lanzaboote, helix,
                     #         noctalia, noctalia-greeter (niri via nixpkgs)
hosts/<host>/        # default.nix + hardware-configuration.nix per machine
modules/nixos/       # shared system modules (core, boot, desktop-niri, gaming, ...)
home/                # home-manager modules (common/ = distro-agnostic; personal/ = desktop)
overlays/            # package overrides
pkgs/                # custom packages not in nixpkgs
inventory/           # captured Arch system state (historical reference)
```

- One concern per module; hosts compose modules + set host-specific options.
  Machine-specific config lives with the host (hosts/home-g16/hardware.nix),
  so modules/nixos/ stays host-agnostic.
- Prefer native NixOS/home-manager options over raw dotfiles; use
  `xdg.configFile` to ship verbatim configs only when no module exists.
- Comment-light, idiomatic Nix; pin nothing without a reason.
