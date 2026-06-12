# Migration Plan: CachyOS → NixOS flake

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done · `[?]` blocked on user

## Decisions

### Settled
- Home-manager as NixOS module (not standalone) on NixOS hosts.
- Bootloader: lanzaboote (systemd-boot + sbctl signing), chainloaded by
  existing rEFInd on the shared ESP. `configurationLimit ≤ 5` (ESP ~930 MB free).
- Filesystem: btrfs on nvme0n1p8, subvols `@ @home @nix @log`,
  `noatime,compress=zstd:1,commit=120`.
- Vanilla kernel (`linuxPackages`), standard Proton; no CachyOS variants.
- zram swap (`zramSwap.enable`); no swap partition currently.
- Secrets management: deferred (revisit when first real secret appears;
  likely sops-nix).
- Drop entirely (Arch/CachyOS-specific): downgrade, paru, reflector,
  cachyos-{hello,hooks,keyring,mirrorlist,v3-mirrorlist,v4-mirrorlist,
  rate-mirrors,settings,kernel-manager,packageinstaller,fish-config},
  linux-cachyos-headers, refind-btrfs (stays on Arch side), ntp (NixOS
  uses systemd-timesyncd).

- Laptop hostname: **home-g16**. School/work hostnames TBD when scaffolded.
- Channel: **nixos-unstable**.
- School/work: **some will be home-manager-only on foreign distros** — flake
  exposes standalone `homeConfigurations` too; home/ modules must stay
  distro-agnostic (no NixOS-only assumptions inside home/).
- Hibernation: **no** — zram only.

- Stale ~/.config dirs CONFIRMED leftovers (hypr/waybar/cosmic/mako/swaync/
  fuzzel/nvim/micro/armcord/webcord/dorion/equibop/lightcord/hyprpanel/
  DankMaterialShell/niri-dms/...) — do not port these.
- **nushell is the primary interactive shell** (launched by ghostty); fish is
  the login shell only (nushell can't be a login shell) and launches
  niri-session on tty. Port BOTH ~/.config/nushell and ~/.config/fish.
- helix: **track -git** via flake input `github:helix-editor/helix` (user
  needs master-only SystemVerilog changes).
- supergfxd: dropped per user — not needed on NixOS.

### Pending user input
(none currently)

## Phases

### Phase 0 — Tooling (done)
- [x] Nix installed on Arch, flakes + trusted-users enabled, daemon running
- [x] mcp-nixos MCP server connected
- [x] Repo scaffolding: git init, CLAUDE.md, PLAN.md, inventory/, subagent def

### Phase 1 — Inventory & package mapping
- [x] Capture: pkgs-explicit.txt, pkgs-foreign.txt, services.txt, etc/ copies,
      hardware.txt, dotconfig-dirs.txt, gaming-meta-deps.txt, howdy-config.ini,
      /usr/local/bin scripts (ac.fish/bat.fish — AC/battery udev hooks)
- [x] `MAPPING.md` produced (subagent, all attrs verified on unstable):
      48 nixpkgs, 22 module, 3 flake, 19 drop, 2 RESEARCH
      (diskonaut: not in nixpkgs, near-dead upstream — drop or pkgs/;
       slang-server-bin: provisionally `sv-lang`, verify slangd binary later)
- [ ] Capture dotfile diffs for active programs (what's customized vs default).

### Phase 2 — Flake skeleton (bootable minimum)
- [x] flake.nix: nixpkgs(unstable), home-manager, lanzaboote v1.0.0 (all with
      follows). niri via nixpkgs `programs.niri` — no niri-flake needed.
- [x] hosts/home-g16: hand-written hardware-configuration.nix (verify against
      `nixos-generate-config` at install), default.nix, stateVersion 26.05
- [x] modules/nixos/core.nix: nix settings, fish, user, NetworkManager+openvpn
      plugin, resolved, zram(100% zstd), firewall, bluetooth, pipewire, avahi,
      fwupd, fstrim, hidraw udev rules (VIA kbd + 1915:232a)
- [x] modules/nixos/nvidia.nix: open module, prime offload w/ bus IDs,
      powerManagement covers NVreg_PreserveVideoMemoryAllocations
- [x] modules/nixos/desktop-niri.nix: programs.niri, xwayland-satellite,
      gnome-keyring. No DM — fish launches niri-session from tty (as on Arch).
- [x] modules/nixos/boot.nix: lanzaboote pkiBundle=/var/lib/sbctl,
      configurationLimit=4, canTouchEfiVariables=false (rEFInd owns BootOrder),
      linuxPackages_latest, Arch kernelParams ported (incl. i915 backlight quirk)
- [x] modules/nixos/asus.nix: power-profiles-daemon, ananicy-cpp +
      ananicy-rules-cachyos, howdy (control=sufficient) + linux-enable-ir-emitter.
      supergfxd DROPPED per user (not needed).
- [x] Port remaining /etc bits: 99-power-saving.rules + ac/bat.fish ported
      into asus.nix as store-pathed fish scripts + udev rules (brightness +
      60/240 Hz switching). intel_lpmd_control calls OMITTED — re-add when
      intel-lpmd is packaged (research item stands).
- [x] plymouth: enabled, "spinner" theme. Requirement: black bg, logo toward
      bottom, NOT centered firmware/ASUS logo (so not bgrt). Verify look on
      first real boot; if wrong, try themePackages or disable — user is fine
      with default-or-off as fallback.
- [x] greetd: confirmed NOT wanted (disabled on Arch too) — no DM, fish
      launches niri-session. Settled.
- Gaming module spec (Phase 3): programs.steam.enable +
      programs.steam.protontricks.enable + umu-launcher, winetricks,
      vulkan-tools packages. NO gamemode/gamescope/mangohud (never installed).
- [x] `nix flake check` passes
- [x] toplevel build passes (`nix build .#nixosConfigurations.home-g16.config.system.build.toplevel`)

### Phase 3 — Home-manager modules (bulk, subagent-heavy)
- [x] home/ skeleton + common module set (CLI per MAPPING.md; diskonaut → ncdu
      substitute; slang-server-bin DEFERRED to the very end per user)
- [x] batch 1 (shells/editor/CLI) COMPLETE: fish, nushell, starship, ghostty
      (vendored config; hm module can't express repeated palette keys), helix
      (-git input + vendored transparent themes; SystemVerilog LSP commented
      out as deferred), git (faithful: gmail identity + lfs only), cli.nix
      (zoxide/carapace fish+nu integrations, full CLI package set, ncdu sub)
- [x] batch 2 (desktop) COMPLETE: niri (vendored KDL, dms/ excluded),
      noctalia (flake homeModule; see open item below), vicinae, satty,
      desktop-tools (+wl-clipboard), theming (bibata cursor, gtk, qtct,
      mimeapps), fonts (emoji default). asusd enabled system-side (asusctl/
      rog-control-center were dep-installed on Arch, used by niri binds).
      LESSON: paru -Qet hides dep-installed tools that configs rely on —
      batch 3 must check niri/mimeapps references against `paru -Q`.
      Open items from batch 2:
      - noctalia RESOLVED (user caught subagent error): user runs v5.0.0 and
        settings.json IS the live v5 config (schema v31); the TOML switch is
        upstream-newer than their build. Input pinned to running rev
        bd74c3461dc3...ac4f. settings.json is runtime-mutable (Settings UI
        writes it) so it must NOT be hm-managed — goes in the Phase 4
        "mutable state to copy to new /home" list instead.
      - GTK theme oomox-BWnB (custom oomox output) not vendored; icon theme
        name in settings.ini was an artifact. Decide post-install (nwg-look
        or pkgs/ derivation).
      - qt6ct color_scheme_path now %APPDIR% token — verify at runtime.
- [x] gaming: modules/nixos/gaming.nix (steam + protontricks options,
      umu-launcher/winetricks/vulkan-tools) wired into host
- [x] fish + starship + carapace + zoxide (port ~/.config/fish, starship.toml)
- [x] batch 3 (apps/media/syncthing) COMPLETE: apps (no config vendoring —
      all runtime-written, Phase 4 copy list), mpv (hwdec port), zathura
      (zathurarc), cmus/vimiv/picard plain packages, syncthing hm user
      service. vesktop settings un-vendored by lead (runtime-written, was
      already on Phase 4 copy list). Post-install check:
      claude-code-url-handler.desktop name in mimeapps.
- [x] ghostty, helix (-git → flake or nixpkgs?), git, mpv, zathura, vimiv, cmus,
      picard, syncthing (user service), playerctl. NOT beets (never
      installed — only a stale library.db in ~/.config/beets)
- [x] niri config + noctalia + vicinae + satty + nwg-displays/look + qt6ct theming
- [x] Apps: firefox, chromium, vesktop, prismlauncher, teams-for-linux,
      tor-browser, cursor (code-cursor), claude-code, android-tools, gcloud
- [x] Per-host split: home/common (shells/editor/CLI, distro-agnostic) vs
      home/personal (desktop+apps). school/work compose home/common + own
      extras when scaffolded (Phase 5).
- [x] Full build passes; dotfiles spot-checked in the closure (fish
      niri-launch, nushell, ghostty->nu, helix themes, niri kdl, udev
      power rules). PHASE 3 COMPLETE 2026-06-11.

### Phase 4 — Install to p8 (user-driven sudo)

Runbook (user runs the sudo commands via `!`; lead verifies between steps).
Arch + rEFInd stay untouched throughout = rollback path.

1. Mount target (UUID 1198bc8f-1186-44a5-aed4-e9a0bbb80ab6 = p8):
   ```
   sudo mkdir -p /mnt/nixos
   sudo mount -o subvol=@,noatime,compress=zstd:1,commit=120 /dev/nvme0n1p8 /mnt/nixos
   sudo mkdir -p /mnt/nixos/{home,nix,var/log,boot}
   sudo mount -o subvol=@home,noatime,compress=zstd:1,commit=120 /dev/nvme0n1p8 /mnt/nixos/home
   sudo mount -o subvol=@nix,noatime,compress=zstd:1,commit=120 /dev/nvme0n1p8 /mnt/nixos/nix
   sudo mount -o subvol=@log,noatime,compress=zstd:1,commit=120 /dev/nvme0n1p8 /mnt/nixos/var/log
   sudo mount /dev/nvme0n1p1 /mnt/nixos/boot
   ```
2. Cross-check hardware config (lead diffs output vs ours):
   `nix shell nixpkgs#nixos-install-tools -c sudo nixos-generate-config --root /mnt/nixos --show-hardware-config`
3. Copy Secure Boot keys BEFORE install (lanzaboote signs during install):
   `sudo mkdir -p /mnt/nixos/var/lib && sudo cp -a /var/lib/sbctl /mnt/nixos/var/lib/`
4. ESP space check: `df -h /boot` (need room for ~4 generations of UKIs).
5. Install (interactive root-password prompt at the end). NOTE: sudo resets
   PATH (secure_path), so nix-shell-provided binaries vanish under sudo —
   always use the absolute store path of the tools:
   `sudo $(nix build nixpkgs#nixos-install-tools --no-link --print-out-paths)/bin/nixos-install --flake /home/zaheenj/nix#home-g16 --root /mnt/nixos`
   Step 2 cross-check DONE 2026-06-11: adopted rtsx_pci_sdmmc initrd module +
   hardware.cpu.intel.npu.enable; generator's other deltas were artifacts of
   the stray /boot mount layer or intentionally-stricter choices of ours.
6. Verify before reboot: `ls /mnt/nixos/boot/EFI/Linux/` shows signed
   nixos-*.efi UKIs; `sudo sbctl verify` on them passes.
7. Copy mutable user state to new home (list below), then
   `sudo chown -R 1000:100 /mnt/nixos/home/zaheenj`.
   LESSON (hit on 2026-06-11): rsync drops source dirs by BASENAME into the
   destination — `rsync .config/noctalia DEST/` lands at DEST/noctalia, not
   DEST/.config/noctalia. Sync .config items into DEST/.config/ explicitly.
   Also system-side state (AFTER nixos-install, before reboot):
   `sudo cp -a /etc/NetworkManager/system-connections /mnt/nixos/etc/NetworkManager/`
   (WiFi profiles + passwords). asusd .ron files NOT copied — user confirmed
   they're untouched defaults; asusd regenerates them.
8. Reboot → rEFInd should auto-detect the new entries. First boot: login as
   root (tty), `passwd zaheenj`, then login as zaheenj on tty1 → fish execs
   niri-session.
9. Smoke tests: WiFi, audio, nvidia-offload glxinfo, brightness keys,
   AC/battery udev (unplug → 60 Hz + dim), howdy (`sudo howdy add` to
   re-enroll — model migration from Arch's /etc/howdy/models is possible but
   re-enrolling is cleaner), plymouth look (black bg, logo placement),
   ESP free space after a couple of rebuilds.

- [ ] Mutable user state to COPY from Arch /home to the new @home (not
      Nix-managed because apps write these at runtime):
      ~/.config/noctalia/ (settings.json, colors.json — Settings UI saves),
      ~/.config/vicinae/, browser profiles (~/.mozilla, ~/.config/chromium),
      ~/.config/vesktop (Discord session), ~/.config/gcloud (creds),
      syncthing state (~/.local/state/syncthing or ~/.config/syncthing),
      ~/.ssh, ~/.gnupg, ~/.claude + claude.json, cmus playlists, helix state,
      plus bulk user data (Documents/Pictures/...) — final list at install.
- [ ] Mount subvols + ESP under /mnt/nixos; generate/verify
      hardware-configuration.nix against `nixos-generate-config --root`
- [ ] Copy sbctl keys into target /var/lib/sbctl
- [ ] Copy howdy face models /etc/howdy/models into target
- [ ] `nixos-install --flake .#g16 --root /mnt/nixos` (via nixos-install-tools)
- [ ] Verify rEFInd sees the NixOS systemd-boot entry; first boot; howdy/
      face-auth and nvidia offload smoke tests
- [ ] ESP space check after 2-3 generations

### Phase 5 — Post-install
- [ ] Iterate natively on NixOS (`nixos-rebuild switch --flake`)
- [ ] school/work hosts skeletons
- [ ] Revisit: rEFInd as sole manager?, secrets (sops-nix), impermanence?,
      btrfs snapshots for /home, binary cache (cachix) if custom builds grow

## Special cases / research list

| Package | Plan |
|---|---|
| cachyos-gaming-meta | → `programs.steam.enable` (+ gamemode/gamescope/mangohud opt-in; steam IS installed on Arch). Contents were wine/proton-cachyos/umu/protontricks/winetricks/vulkan-tools |
| linux-cachyos-nvidia-open | → vanilla kernel + `hardware.nvidia.open = true` |
| howdy-git + linux-enable-ir-emitter | RESOLVED: `services.howdy` (control=sufficient) + `services.linux-enable-ir-emitter` exist in nixpkgs. Migrate `/etc/howdy/models` (face data) + port howdy-config.ini settings at install |
| niri-git | → niri-flake (sodiboo) or nixpkgs niri; -git tracking via flake input |
| noctalia-git | → upstream noctalia-shell flake input (verify it exists) |
| vicinae-bin | RESEARCH: nixpkgs or upstream flake |
| helix-git | → flake input `github:helix-editor/helix` (decided: user needs master for SystemVerilog) |
| slang-server-bin | RESEARCH: SystemVerilog LSP, likely not in nixpkgs → pkgs/ |
| intel-lpmd-git | NO NixOS module, not in nixpkgs, no upstream flake. Interim: power-profiles-daemon. Custom pkg+unit deferred to Phase 5; ac/bat.fish scripts depend on it |
| supergfxd | DROPPED per user — not needed |
| ananicy-cpp | `services.ananicy` + ananicy-rules-cachyos package (verify name) |
| ufw | RESOLVED: `networking.firewall.enable`, no extra ports. Arch's only custom rules were KDE Connect 1714-1764 for Valent; user confirmed Valent unused — dropped (2026-06-11) |
| ydotool | `programs.ydotool.enable` (verify) |
| tzupdate | verify `services.tzupdate` exists; else timezone static |
| sbctl/efitools/fwupd/sof-firmware/intel-ucode | lanzaboote handles signing; `services.fwupd.enable`; `hardware.enableRedistributableFirmware` + `hardware.cpu.intel.updateMicrocode` |
| cursor-bin | `code-cursor` (unfree) |
| google-cloud-cli | `google-cloud-sdk` (with components?) |
| carapace-bin / bibata-cursor-theme-bin / teams-for-linux-bin / tor-browser-bin | carapace / bibata-cursors / teams-for-linux / tor-browser (verify) |
| nushell | PRIMARY interactive shell (ghostty launches it); fish remains login shell. Port ~/.config/nushell fully |
| networkmanager-openvpn | `networking.networkmanager.plugins` (verify option) |
| libva-nvidia-driver | nvidia-vaapi-driver pkg |

## Risks

1. **ESP space (930 MB)**: lanzaboote stores kernel+initrd per generation;
   nvidia initrds are fat. Mitigate: configurationLimit, monitor after install.
2. **Howdy**: worst-mapped package; don't block install on it.
3. **Secure boot first boot**: if lanzaboote signing is misconfigured, boot
   entry won't verify — keep Arch + rEFInd untouched as fallback (they are).
4. **Shared /boot**: NixOS and Arch both writing loader entries to one ESP —
   namespace is fine (different entry files), but never let NixOS reformat it.
5. **16 GB RAM + nix builds**: large rebuilds + zram are fine, but avoid
   building chromium-class packages from source; stay on cache-hit paths.
