# NixOS Flake Config — Migration from CachyOS

Multi-host NixOS flake (home-manager as NixOS module) for three machines:
personal laptop (migrating now from CachyOS Arch), school, and work (later).
Modeled on https://nixos-and-flakes.thiscute.world/ conventions.

## Hard facts about the personal machine (verified 2026-06-11)

- ASUS ROG Zephyrus G16: Intel Core Ultra 9 185H (Meteor Lake, Intel Arc iGPU)
  + NVIDIA RTX 4070 Max-Q **hybrid graphics**, 16 GB RAM, Intel CNVi WiFi.
  - Arch uses: supergfxd, nvidia-open kernel module, nvidia-prime, howdy (IR
    face auth) + linux-enable-ir-emitter, intel-lpmd.
- **Secure Boot is ENABLED** with personal sbctl keys (+ Microsoft vendor keys).
  NixOS must use **lanzaboote**, signing with the existing sbctl keys (on Arch
  check `/var/lib/sbctl` or `/usr/share/secureboot`).
- Bootloader: **rEFInd** on the **shared ESP** `/dev/nvme0n1p1` (vfat, mounted
  at `/boot`, only ~930 MB free, shared with Windows + Arch). rEFInd stays;
  it chainloads NixOS's systemd-boot/lanzaboote entries. Keep lanzaboote
  `configurationLimit` low (≤5) — ESP space is the binding constraint.
- NixOS target partition: `/dev/nvme0n1p8`, btrfs, label `NixOS`,
  UUID `1198bc8f-1186-44a5-aed4-e9a0bbb80ab6`, subvolumes `@ @home @nix @log`
  (already created). Arch lives on p7 (don't touch), Windows on p3.
- Mount options (user prefers performance): `noatime,compress=zstd:1,commit=120`.
- Desktop stack: **niri** (wayland, scrollable tiling) + **noctalia** shell +
  xwayland-satellite + vicinae launcher, **greetd** as DM, pipewire audio.
- Shells: **fish** is the login shell (launches niri-session on tty);
  **nushell** is the primary interactive shell (ghostty starts it). Port both
  configs. Plus starship, carapace, zoxide. Editor: **helix** (-git, via
  flake input — user needs master for SystemVerilog).
- No swap partition; Arch uses zram.

## User preferences (load-bearing)

- Vanilla kernel/`linuxPackages`, NOT CachyOS variants. Standard Proton, not
  proton-cachyos (gaming via `programs.steam`; proton-ge-bin optional).
- Performance over conservative defaults (mount flags, zram, etc.).
- No Determinate Systems installer/tooling — upstream Nix only.
- systemd-boot (via lanzaboote) for now; rEFInd-as-manager revisit later.
- Use `paru` not `pacman` for Arch queries.
- User approves all sudo personally. **sudo does not work in Claude's shell**
  (no TTY for password) — ask the user to run sudo commands via `! <cmd>`.

## Workflow rules

- **Never write a NixOS/home-manager option or package name from memory.**
  Verify via mcp-nixos tools (`mcp__nixos__nix`, search/info actions) or
  `nix search`. Wrong-but-plausible option names are the #1 failure mode.
- Validation ladder (run on Arch, no root needed):
  1. `nix flake check` — seconds, catches most errors
  2. `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
  3. `nixos-rebuild build-vm --flake .#<host>` — boots QEMU (hw-specific
     bits like nvidia/secure-boot won't be testable in VM)
- nixos-* tools come from `nix shell nixpkgs#nixos-install-tools` /
  `nixpkgs#nixos-rebuild` — nothing installed globally on Arch.
- Bulk module-writing goes to the `nix-module-writer` subagent (Sonnet) to
  save usage; planning/review/decisions stay with the lead model.
- `inventory/` holds captured Arch state (packages, services, /etc files) —
  it is the migration source of truth. Don't regenerate without reason.
- Update PLAN.md checkboxes as work completes; commit early and often.
- The deal with the user: they manage at a high level; bring them decisions
  (especially boot/filesystem/kernel-adjacent), not minutiae.

## Repo layout (target)

```
flake.nix            # inputs: nixpkgs, home-manager, lanzaboote, niri-flake, ...
hosts/<host>/        # default.nix + hardware-configuration.nix per machine
modules/nixos/       # shared system modules (core, desktop-niri, gaming, nvidia, ...)
home/                # home-manager modules, one dir/file per program
overlays/            # package overrides
pkgs/                # custom packages not in nixpkgs
inventory/           # captured Arch system state (reference, not imported)
```

- One concern per module; hosts compose modules + set host-specific options.
- Prefer native NixOS/home-manager options over raw dotfiles; use
  `xdg.configFile` to ship verbatim configs only when no module exists.
- Comment-light, idiomatic Nix; pin nothing without a reason.
