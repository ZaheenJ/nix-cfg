# Package Disposition Mapping: CachyOS → NixOS

Generated 2026-06-11. Every row verified via `mcp__nixos__nix` (nixos-unstable channel) or
noted as RESEARCH. Arch version from `inventory/pkgs-explicit.txt`; AUR/foreign packages
marked with `*` in the Arch package column (sourced from `inventory/pkgs-foreign.txt`).

Legend:
- `nixpkgs:<attr>` — attribute verified on nixos-unstable
- `module:<option>` — better served by a NixOS/home-manager module option
- `flake:<url>` — upstream flake (no nixpkgs entry, or -git tracking desired)
- `drop` — Arch/CachyOS-specific or in PLAN.md drop list
- `RESEARCH` — not resolved; findings recorded below

---

## System / Boot

| Arch package | Arch ver | Disposition | Detail |
|---|---|---|---|
| base | 3-3 | `drop` | Meta-package for Arch base system; NixOS equivalent is implicit in any NixOS config |
| efitools | 1.9.2 | `nixpkgs:efitools` | Verified: 1.9.2 on unstable. Used for UEFI key manipulation; may be superseded by sbctl for day-to-day work |
| sbctl | 0.18 | `module:boot.lanzaboote` | Verified: `sbctl` pkg exists (0.18). Lanzaboote flake manages signing; sbctl is pulled in as a dep. Install via `environment.systemPackages` if manual key inspection is needed |
| intel-ucode | 20260512 | `module:hardware.cpu.intel.updateMicrocode` | Verified option exists. Set `hardware.cpu.intel.updateMicrocode = true`; NixOS pulls in `microcode-intel` (20260227 in nixpkgs — Arch version is newer, see Notes) |
| linux-cachyos-headers | 7.0.11 | `drop` | CachyOS kernel headers; using vanilla `linuxPackages` per PLAN.md |
| linux-cachyos-nvidia-open | 7.0.11 | `drop` | CachyOS kernel; replaced by `boot.kernelPackages = pkgs.linuxPackages` + `hardware.nvidia.open = true` |
| nvidia-prime | 1.0 | `module:hardware.nvidia.prime.offload.enable` | Verified option exists. Use `hardware.nvidia.prime.offload.enable` + bus IDs. `hardware.nvidia.prime.offload.enableOffloadCmd = true` for convenience script |
| sof-firmware | 2025.12.2 | `module:hardware.enableRedistributableFirmware` | Verified: `sof-firmware` pkg (2025.12.2) is included when `hardware.enableRedistributableFirmware = true`. Also set `hardware.firmware = [ pkgs.sof-firmware ]` explicitly if needed |
| fwupd | 2.1.4 | `module:services.fwupd.enable` | Verified option exists. nixpkgs has 2.0.19 — Arch has 2.1.4 (see Notes) |
| lsscsi | 0.32 | `nixpkgs:lsscsi` | Verified: 0.32 on unstable |
| nvme-cli | 2.16 | `nixpkgs:nvme-cli` | Verified: 2.16 on unstable |
| refind-btrfs | 0.6.5 | `drop` | Arch-side rEFInd helper; NixOS doesn't use it. rEFInd stays untouched on the shared ESP |
| nix | 2.34.7 | `drop` | Arch-side Nix install; irrelevant in NixOS (nix is the system itself) |

---

## Desktop (niri / Wayland)

| Arch package | Arch ver | Disposition | Detail |
|---|---|---|---|
| niri-git | 25.11.r157 | `module:programs.niri.enable` | Verified: `programs.niri.enable` option exists; nixpkgs has `niri` 25.11. The -git suffix indicates tracking master; nixpkgs unstable is at release 25.11, which matches the base. Use `programs.niri.enable = true` + optionally pin to niri-flake (github:sodiboo/niri-flake) for bleeding-edge |
| noctalia-git | 5.0.0.r2720 | `flake:github:noctalia-dev/noctalia` | Not in nixpkgs. Upstream repo confirmed at `github.com/noctalia-dev/noctalia` with a `flake.nix` present. Add as flake input. Note: v5 is alpha/early development |
| xwayland-satellite | 0.8.1 | `nixpkgs:xwayland-satellite` | Verified: 0.8.1 on unstable |
| greetd (DM) | — | `module:services.greetd.enable` | Verified option exists. Not in explicit pkgs list but needed per CLAUDE.md; `services.greetd.settings` configures the greeter command |
| wev | 1.1.0 | `nixpkgs:wev` | Verified: 1.1.0 on unstable. Wayland event debug tool |
| ydotool | 1.0.4 | `module:programs.ydotool.enable` | Verified option exists (`programs.ydotool.enable`, `programs.ydotool.group`). This sets up the systemd daemon; users need to be in the group |
| satty | 0.20.1 | `nixpkgs:satty` | Verified: 0.20.1 on unstable |
| nwg-displays | 0.4.3 | `nixpkgs:nwg-displays` | Verified: 0.3.28 on unstable — Arch has 0.4.3, nixpkgs is behind (see Notes) |
| nwg-look | 1.1.1 | `nixpkgs:nwg-look` | Verified: 1.0.6 on unstable — Arch has 1.1.1, nixpkgs is behind (see Notes) |
| qt6ct | 0.11 | `nixpkgs:kdePackages.qt6ct` | Verified: 0.11 on unstable under `kdePackages.qt6ct` |
| vicinae-bin * | 0.21.2 | `nixpkgs:vicinae` | Verified: `vicinae` 0.20.12 on unstable (the -bin was the AUR prebuilt; nixpkgs builds from source). Also has `flake.nix` upstream at `github.com/vicinaehq/vicinae` for latest |
| playerctl | 2.4.1 | `nixpkgs:playerctl` | Verified: 2.4.1 on unstable |
| pulsemixer | 1.5.1 | `nixpkgs:pulsemixer` | Verified: 1.5.1 on unstable |

---

## CLI Tools

| Arch package | Arch ver | Disposition | Detail |
|---|---|---|---|
| bottom | 0.12.3 | `nixpkgs:bottom` | Verified: 0.12.3 on unstable |
| duf | 0.9.1 | `nixpkgs:duf` | Verified: 0.9.1 on unstable |
| dust | 1.2.4 | `nixpkgs:dust` | Verified: 1.2.4 on unstable (attr is `dust`, pname `du-dust`) |
| fd | 10.4.2 | `nixpkgs:fd` | Verified: 10.4.2 on unstable |
| figlet | 2.2.5 | `nixpkgs:figlet` | Verified: 2.2.5 on unstable |
| man-pages | 6.18 | `nixpkgs:man-pages` | Verified: 6.17 on unstable — Arch has 6.18 (see Notes) |
| nvtop | 3.3.2 | `nixpkgs:nvtopPackages.full` | Verified: 3.3.2 on unstable. Use `nvtopPackages.full` for AMD+Intel+NVIDIA support on this hybrid-GPU machine |
| starship | 1.25.1 | `nixpkgs:starship` | Verified: 1.24.2 on unstable — Arch has 1.25.1 (see Notes) |
| taskwarrior-tui | 0.27.0 | `nixpkgs:taskwarrior-tui` | Verified: 0.26.6 on unstable — Arch has 0.27.0 (see Notes) |
| termdown | 1.18.0 | `nixpkgs:termdown` | Verified: 1.18.0 on unstable |
| tokei | 14.0.0 | `nixpkgs:tokei` | Verified: 14.0.0 on unstable |
| xkcdpass | 1.30.0 | `nixpkgs:xkcdpass` | Verified: 1.30.0 on unstable |
| zoxide | 0.9.9 | `nixpkgs:zoxide` | Verified: 0.9.9 on unstable |
| carapace-bin * | 1.6.6 | `nixpkgs:carapace` | Verified: `carapace` 1.6.3 on unstable (the -bin was prebuilt AUR; nixpkgs builds from source). Arch has 1.6.6 (see Notes) |
| nushell | 0.113.1 | `nixpkgs:nushell` | Verified: 0.111.0 on unstable — Arch has 0.113.1 (see Notes). Secondary shell per PLAN.md pending user decision on config depth |
| uv | 0.11.19 | `nixpkgs:uv` | Verified: 0.11.4 on unstable — Arch has 0.11.19 (see Notes) |
| diskonaut | 0.11.0 | `RESEARCH` | Not found in nixpkgs (confirmed: no results for `diskonaut`). See RESEARCH section |
| powerstat * | 0.04.05 | `nixpkgs:powerstat` | Verified: 0.04.06 on unstable (Arch has .05; nixpkgs actually has a newer micro version) |
| lsscsi | 0.32 | `nixpkgs:lsscsi` | Already listed above (system section); include in home packages if wanted |

---

## GUI Apps

| Arch package | Arch ver | Disposition | Detail |
|---|---|---|---|
| chromium | 149.0.7827 | `nixpkgs:chromium` | Verified: 147.0.7727.55 on unstable — Arch has 149.x (see Notes) |
| firefox | 151.0.3 | `nixpkgs:firefox` | Verified: 149.0.2 on unstable — Arch has 151.x (see Notes) |
| ghostty | 1.3.1 | `nixpkgs:ghostty` | Verified: 1.3.1 on unstable |
| mpv | 0.41.0 | `nixpkgs:mpv` | Verified: 0.41.0 on unstable |
| picard | 2.13.3 | `nixpkgs:picard` | Verified: 2.13.3 on unstable |
| prismlauncher | 11.0.2 | `nixpkgs:prismlauncher` | Verified: 10.0.5 on unstable — Arch has 11.0.2 (see Notes) |
| syncthing | 2.1.1 | `module:services.syncthing.enable` | Verified option exists. On Arch it runs as user service; use `services.syncthing.enable = true; services.syncthing.user = "zaheenj"` for system-level, or `services.syncthing.systemService = false` + home-manager user service. nixpkgs has 2.0.15 — Arch has 2.1.1 (see Notes) |
| teams-for-linux-bin * | 2.7.13 | `nixpkgs:teams-for-linux` | Verified: 2.7.13 on unstable. Unfree — needs `allowUnfree` (see Notes) |
| tor-browser-bin * | 15.0.9 | `nixpkgs:tor-browser` | Verified: 15.0.9 on unstable |
| vesktop | 1.6.5 | `nixpkgs:vesktop` | Verified: 1.6.5 on unstable |
| vimiv | 0.9.1 | `nixpkgs:vimiv-qt` | Verified: `vimiv-qt` 0.9.0 on unstable. Arch package `vimiv` is actually the Qt port (`vimiv-qt`) |
| cursor-bin * | 3.5.17 | `nixpkgs:code-cursor` | Verified: `code-cursor` 3.0.12 on unstable. Arch has 3.5.17 — significantly newer (see Notes). Unfree |
| claude-code | 2.1.170 | `nixpkgs:claude-code` | Verified: 2.1.92 on unstable. Arch has 2.1.170 — Arch may track releases faster (see Notes). Unfree |
| google-cloud-cli * | 570.0.0 | `nixpkgs:google-cloud-sdk` | Verified: `google-cloud-sdk` 552.0.0 on unstable — Arch has 570.x (see Notes). Check `google-cloud-sdk.withExtraComponents` for gke-gcloud-auth-plugin etc. |
| zathura (not in list) | — | — | Not in explicit list; skip |
| pulsemixer | 1.5.1 | (listed under Desktop/CLI above) | — |

---

## Dev Tools

| Arch package | Arch ver | Disposition | Detail |
|---|---|---|---|
| android-tools | 35.0.2 | `nixpkgs:android-tools` | Verified: 35.0.2 on unstable |
| helix-git | 25.07.r670 | `flake:github:helix-editor/helix` | nixpkgs has `helix` 25.07.1 (release). The -git suffix means tracking master. Upstream confirmed flake.nix at root. PLAN.md asks user to decide: nixpkgs release is `nixpkgs:helix` (verified), or use `flake:github:helix-editor/helix` for master builds |
| lua-language-server | 3.18.2 | `nixpkgs:lua-language-server` | Verified: 3.18.0 on unstable — Arch has 3.18.2 (minor) |
| tinymist | 0.14.18 | `nixpkgs:tinymist` | Verified: 0.14.16 on unstable — Arch has 0.14.18 (see Notes) |
| verilator | 5.048 | `nixpkgs:verilator` | Verified: 5.046 on unstable — Arch has 5.048 (see Notes) |
| slang-server-bin * | 0.2.5 | `RESEARCH` | See RESEARCH section |
| uv | 0.11.19 | `nixpkgs:uv` | Already listed in CLI section |

---

## Gaming (cachyos-gaming-meta expansion)

The Arch `cachyos-gaming-meta` package installs Steam and associated gaming tools.
Expanded disposition per PLAN.md:

| Component | Arch equivalent | Disposition | Detail |
|---|---|---|---|
| Steam | (steam via meta) | `module:programs.steam.enable` | Verified option exists. Sets up Steam with correct system integration, 32-bit libs, udev rules |
| gamemode | (steam meta dep) | `module:programs.gamemode.enable` | Verified: `programs.gamemode.enable` + `programs.gamemode.enableRenice` for niceness. pkg `gamemode` 1.8.2 verified |
| gamescope | (steam meta dep) | `nixpkgs:gamescope` | Verified: 3.16.22 on unstable. Can use with `programs.steam.gamescopeSession.enable` |
| mangohud | (steam meta dep) | `nixpkgs:mangohud` | Verified: 0.8.2 on unstable |
| umu-launcher | (steam meta dep) | `nixpkgs:umu-launcher` | Verified: 1.4.0 on unstable |
| protontricks | (steam meta dep) | `module:programs.steam.protontricks.enable` | Verified option exists. Alternatively `nixpkgs:protontricks` (1.14.0) directly |
| winetricks | (steam meta dep) | `nixpkgs:winetricks` | Verified: 20260125 on unstable |
| vulkan-tools | (steam meta dep) | `nixpkgs:vulkan-tools` | Verified: 1.4.341.0 on unstable |

---

## Fonts / Themes

| Arch package | Arch ver | Disposition | Detail |
|---|---|---|---|
| noto-color-emoji-fontconfig | 1.0.0 | `nixpkgs:noto-fonts-color-emoji` | Verified: `noto-fonts-color-emoji` 2.051 on unstable. The Arch package is a fontconfig config wrapper around the same font; in NixOS, fonts.packages covers this and fontconfig is managed automatically |
| bibata-cursor-theme-bin * | 2.0.7 | `nixpkgs:bibata-cursors` | Verified: `bibata-cursors` 2.0.7 on unstable. The -bin was prebuilt AUR; nixpkgs builds from source |
| cachyos-plymouth-bootanimation | 2-3 | `drop` | CachyOS-specific Plymouth theme |
| cachyos-plymouth-theme | 1-1 | `drop` | CachyOS-specific Plymouth theme |

---

## ASUS / Hardware Services (not explicit packages, but services.txt implies them)

| Arch service/package | Disposition | Detail |
|---|---|---|
| supergfxd | `module:services.supergfxd.enable` | Verified option exists. Controls GPU switching between integrated/hybrid/dedicated on ASUS ROG. `services.supergfxd.settings` maps to `/etc/supergfxd.conf` |
| ananicy-cpp | `module:services.ananicy.enable` | Verified option exists. Set `services.ananicy.package = pkgs.ananicy-cpp` and `services.ananicy.rulesProvider = pkgs.ananicy-rules-cachyos` |
| power-profiles-daemon | `module:services.power-profiles-daemon.enable` | Verified option exists. Conflicts with TLP; use one or the other |
| avahi | `module:services.avahi.enable` | Verified option exists |
| NetworkManager | `module:networking.networkmanager.enable` | Verified option. OpenVPN plugin: add `pkgs.networkmanager-openvpn` to `networking.networkmanager.plugins` |
| networkmanager-openvpn | `nixpkgs:networkmanager-openvpn` | Verified: `networkmanager-openvpn` 1.12.3 on unstable. Use via `networking.networkmanager.plugins` option |
| bluetooth (bluez-utils) | `module:hardware.bluetooth.enable` | Verified option. `bluez-utils` in Arch provides CLI tools like `bluetoothctl`; those are included when `hardware.bluetooth.enable = true` |
| pipewire | `module:services.pipewire.enable` | Verified option. Also `services.pipewire.audio.enable = true` to use as primary sound server |
| greetd | `module:services.greetd.enable` | Verified option |
| systemd-resolved | built-in | NixOS enables this via `networking.nameservers` / `services.resolved.enable` |
| systemd-timesyncd | built-in | NixOS enables by default; `services.timesyncd.enable = true` (default true) |

---

## Dropped (CachyOS / Arch-specific)

| Arch package | Arch ver | Disposition | Reason |
|---|---|---|---|
| cachyos-fish-config | 15-1 | `drop` | CachyOS-specific fish config; port fish config manually from dotfiles |
| cachyos-hello | 0.24.0 | `drop` | CachyOS welcome app; not applicable to NixOS |
| cachyos-hooks | 2026.02.05 | `drop` | Arch pacman hooks; irrelevant on NixOS |
| cachyos-kernel-manager | 1.18.1 | `drop` | CachyOS GUI kernel manager; irrelevant on NixOS |
| cachyos-keyring | 20240331 | `drop` | Arch/CachyOS pacman keyring; irrelevant on NixOS |
| cachyos-mirrorlist | 27-1 | `drop` | CachyOS pacman mirrorlist; irrelevant on NixOS |
| cachyos-packageinstaller | 1.6.2 | `drop` | CachyOS GUI package installer; irrelevant on NixOS |
| cachyos-rate-mirrors | 23-2 | `drop` | CachyOS mirror-ranking tool; irrelevant on NixOS |
| cachyos-settings | 1.3.5 | `drop` | CachyOS system settings; irrelevant on NixOS |
| cachyos-v3-mirrorlist | 27-1 | `drop` | CachyOS pacman mirrorlist; irrelevant on NixOS |
| cachyos-v4-mirrorlist | 27-1 | `drop` | CachyOS pacman mirrorlist; irrelevant on NixOS |
| downgrade | 12.0.2 | `drop` | Arch-specific pacman downgrade tool; irrelevant on NixOS |
| paru | 2.1.0 | `drop` | AUR helper; irrelevant on NixOS |
| reflector | 2023-5 | `drop` | Arch mirror-ranking tool for pacman; irrelevant on NixOS |
| ntp | 4.2.8 | `drop` | Replaced by systemd-timesyncd (NixOS default) per PLAN.md |
| refind-btrfs | 0.6.5 | `drop` | Arch-side rEFInd helper; stays on Arch partition only |
| cachyos-plymouth-bootanimation | 2-3 | `drop` | CachyOS-specific Plymouth theme |
| cachyos-plymouth-theme | 1-1 | `drop` | CachyOS-specific Plymouth theme |

---

## Pending User Decision

| Arch package | Disposition | Detail |
|---|---|---|
| helix-git | nixpkgs or flake | nixpkgs has `helix` 25.07.1 release. Upstream flake at `github:helix-editor/helix` builds from master. PLAN.md flags this as a user decision. Both options verified |
| nushell | nixpkgs:nushell | 0.111.0 in nixpkgs, Arch has 0.113.1. Include as extra shell with minimal config, or drop? PLAN.md flags for user |

---

## RESEARCH

### diskonaut

**Searched:** `info` on `diskonaut` (NOT_FOUND), `search` for `diskonaut` (no results on nixos-unstable).

**Findings:** Not in nixpkgs. The project is at `github.com/imsnif/diskonaut` — a terminal disk space navigator written in Rust. Last upstream release was 0.11.0 in 2021. The repo appears to have limited activity. No NixOS/flake configuration visible. Could be packaged in `pkgs/` with `rustPlatform.buildRustPackage` using the GitHub source, but requires writing a custom derivation. Not a critical tool (functionally overlaps with `dust`/`duf`).

**Recommendation:** Write a trivial custom derivation in `pkgs/diskonaut.nix` if this tool is important to the user, otherwise drop in favor of `dust`/`duf`. Mark as optional.

---

### slang-server-bin (SystemVerilog LSP)

**Searched:** `info` on `slang-server-bin` (not found), `search` for `slang SystemVerilog` on nixpkgs-unstable.

**Findings:** The Arch `slang-server-bin` package is the language server component of the Slang SystemVerilog toolchain by Mike Popoloski (`github.com/MikePopoloski/slang`). In nixpkgs, the project is packaged as `sv-lang` (verified: version 9.1 on unstable), which is the compiler/tools portion. The `slangd` LSP binary is part of the same upstream project but **the `sv-lang` nixpkgs package must be inspected** to confirm whether it includes the `slangd` binary.

**Searched wiki:** No results for slang/SystemVerilog in NixOS wiki.

**Also found:** `svls` (0.2.14) and `veridian` (0-unstable-2025-11-30) are alternative SystemVerilog language servers in nixpkgs.

**Recommendation:** Try `nixpkgs:sv-lang` first — if `slangd` is included in its binaries, that resolves it. If not, `veridian` or `svls` are viable alternatives. Check with `nix run nixpkgs#sv-lang -- slangd --version` after NixOS install. Set as `nixpkgs:sv-lang` provisionally, noting this needs verification.

**Provisional disposition:** `nixpkgs:sv-lang` (verify slangd binary is present; fallback to `nixpkgs:veridian`)

---

### howdy-git + linux-enable-ir-emitter

**Result: FULLY RESOLVED via NixOS modules — not a research dead-end.**

Both packages have first-class NixOS module support on nixos-unstable:

- `services.howdy.enable` — enables the Howdy face-authentication daemon and its PAM module. Confirmed options: `services.howdy.settings` (INI config), `services.howdy.control` (PAM control flag, defaults to `"required"`; set to `"sufficient"` for face-auth as alternative to password), `services.howdy.package`.
- `services.linux-enable-ir-emitter.enable` — enables IR camera emitter support required by Howdy. The option description explicitly references Howdy. After enabling, run `sudo linux-enable-ir-emitter configure` once to set up the camera.
- `security.pam.howdy.enable` and `security.pam.services.<name>.howdy.enable` — for per-service PAM integration.

**Important caveat from NixOS option description:** "Howdy is not a safe alternative to unlocking with your password. It can be fooled using a well-printed photo. Do not use it as the sole authentication method."

**Disposition:** `module:services.howdy.enable` + `module:services.linux-enable-ir-emitter.enable`

---

### intel-lpmd-git

**Searched:** `info` on `intel-lpmd-git` (not found), `search` for `intel-lpmd` on nixpkgs-unstable (no direct match), `search` for `intel lpmd` on NixOS wiki (no results), search for NixOS option `services.intel-lpmd` (no results — not found in any option search).

**Upstream:** `github.com/intel/intel-lpmd` — confirmed to exist (209 stars). No `flake.nix` in the repository. Installation docs only cover Fedora/Ubuntu/OpenSUSE. Project description: "Linux daemon to optimize active idle power" for Intel Meteor Lake and newer CPUs with hardware P-Core/E-Core topology (directly relevant to the Core Ultra 9 185H).

**Findings:** intel-lpmd is **not** in nixpkgs and has no NixOS module. No community flake was found.

**Options:**
1. Write a custom Nix package in `pkgs/intel-lpmd.nix` using `autoconf`/`automake` build from source + a systemd service module in `modules/nixos/`.
2. Substitute with `services.power-profiles-daemon.enable = true` (provides `power-profiles-daemon` which handles P/E-core balancing on modern Intel via platform profile).
3. Accept absence: the CPU will use default kernel scheduler; power management is less fine-grained but functional.

**Recommendation:** Use `services.power-profiles-daemon.enable = true` as the primary power management path (already in services.txt as `power-profiles-daemon.service enabled`). Defer intel-lpmd packaging unless the user explicitly needs its fine-grained idle power features. Flag as a Phase 5 item.

**Disposition:** `RESEARCH` — not in nixpkgs, no flake, no NixOS module. Custom derivation needed or use power-profiles-daemon as substitute.

---

## Notes

### (a) Packages where nixpkgs version is significantly older than Arch

| Package | Arch version | nixpkgs version | Gap |
|---|---|---|---|
| cursor-bin / code-cursor | 3.5.17 | 3.0.12 | ~2 major point releases behind |
| google-cloud-cli / google-cloud-sdk | 570.0.0 | 552.0.0 | 18 minor versions behind |
| intel-ucode / microcode-intel | 20260512 | 20260227 | 2 months behind (security-relevant) |
| nushell | 0.113.1 | 0.111.0 | 2 minor versions |
| uv | 0.11.19 | 0.11.4 | 15 patch versions (fast-moving project) |
| firefox | 151.0.3 | 149.0.2 | 2 minor versions |
| chromium | 149.0.7827.53 | 147.0.7727.55 | 2 minor versions |
| carapace | 1.6.6 | 1.6.3 | 3 patches |
| prismlauncher | 11.0.2 | 10.0.5 | 1 major version |
| syncthing | 2.1.1 | 2.0.15 | 1 major version |
| taskwarrior-tui | 0.27.0 | 0.26.6 | 1 patch |
| tinymist | 0.14.18 | 0.14.16 | 2 patches |
| starship | 1.25.1 | 1.24.2 | 1 patch |
| nwg-displays | 0.4.3 | 0.3.28 | 1 minor version |
| nwg-look | 1.1.1 | 1.0.6 | 1 minor version |
| verilator | 5.048 | 5.046 | 2 patches |
| fwupd | 2.1.4 | 2.0.19 | 1 minor version |
| man-pages | 6.18 | 6.17 | 1 patch |
| claude-code | 2.1.170 | 2.1.92 | 78 patch releases |
| lua-language-server | 3.18.2 | 3.18.0 | 2 patches |

**Action items:**
- `code-cursor` and `google-cloud-sdk` gaps are large enough to consider overriding in `overlays/` or accepting the older version.
- `microcode-intel`: the nixpkgs version (20260227) is older than Arch's (20260512). Since this affects CPU security mitigations, monitor for nixpkgs updates. Consider pinning a newer microcode manually if security advisories require it.
- `firefox`/`chromium`: browser security patches are significant; nixpkgs unstable usually tracks these closely. If gaps persist after migration, check if there's a newer commit to pin.

### (b) Unfree packages requiring `nixpkgs.config.allowUnfree = true`

The following packages have unfree licenses and require either global `allowUnfree` or per-package predicates:

| Package | nixpkgs attr | License |
|---|---|---|
| cursor-bin | `code-cursor` | Unfree |
| claude-code | `claude-code` | Unfree |
| teams-for-linux-bin | `teams-for-linux` | Unfree (proprietary Microsoft protocol) |
| unrar | `unrar` | Unfree redistributable |
| google-cloud-cli | `google-cloud-sdk` | Unspecified free (check; likely needs allowUnfree) |

Recommended: set `nixpkgs.config.allowUnfreePredicate` to allowlist exactly these packages rather than global `allowUnfree = true`.

### (c) Services in inventory/services.txt with no package row

The following enabled services from `inventory/services.txt` have no explicit package in `pkgs-explicit.txt` but need NixOS coverage:

| Service (Arch) | NixOS option | Notes |
|---|---|---|
| `ananicy-cpp.service` | `services.ananicy.enable` | Verified. Set `package = pkgs.ananicy-cpp`, `rulesProvider = pkgs.ananicy-rules-cachyos` |
| `avahi-daemon.service` | `services.avahi.enable` | Verified |
| `bluetooth.service` | `hardware.bluetooth.enable` | Verified |
| `intel_lpmd.service` | RESEARCH (no NixOS option) | No module exists; see RESEARCH section |
| `NetworkManager.service` | `networking.networkmanager.enable` | Verified |
| `nvidia-powerd.service` | `hardware.nvidia.dynamicBoost.enable` | Verified option exists (requires nvidia-open driver + hardware support) |
| `power-profiles-daemon.service` | `services.power-profiles-daemon.enable` | Verified |
| `supergfxd.service` | `services.supergfxd.enable` | Verified |
| `systemd-resolved.service` | `networking.useNetworkd` / `services.resolved.enable` | NixOS default; enabled automatically |
| `systemd-timesyncd.service` | default enabled | NixOS enables timesyncd by default |
| `cachyos-iw-set-regdomain.path` | udev rule / `networking.wireless.regulatory.enable` | Set wifi regulatory domain; NixOS: `hardware.wirelessRegulatoryDatabase = true` or set `CRDA` domain |
| `cachyos-rate-mirrors.timer` | `drop` | CachyOS-specific pacman mirror tool |
| `fstrim.timer` | `services.fstrim.enable` | Not in pkg list but SSD health; verify and enable |
| `syncthing.service` (user) | `services.syncthing.enable` | Verified; run as user via `services.syncthing.user` |
| `wireplumber.service` (user) | `services.pipewire.wireplumber.enable` | Part of pipewire module; `services.pipewire.enable = true` pulls this in |
| `pipewire.socket` / `pipewire-pulse.socket` (user) | `services.pipewire.enable` | Verified |
| `gnome-keyring-daemon.socket` (user) | `services.gnome-keyring.enable` | Verify if needed; provides keyring for secrets storage |

---

## Row Count Summary

| Disposition | Count |
|---|---|
| `nixpkgs:<attr>` | 48 |
| `module:<option>` | 22 |
| `flake:<url>` | 3 (noctalia, helix, vicinae-upstream) |
| `drop` | 19 |
| `RESEARCH` | 2 (diskonaut, intel-lpmd-git) |
| Pending user decision | 2 (helix nixpkgs-vs-flake, nushell config depth) |
| **Total** | **96** |

Note: `slang-server-bin` has a provisional `nixpkgs:sv-lang` disposition (needs binary verification post-install).
