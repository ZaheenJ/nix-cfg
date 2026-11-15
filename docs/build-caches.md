# Build-cache review: 2026-11-14

The Linux update built successfully and the user confirmed a successful reboot.
Kernel 7.3.4 is running, with no failed system units. The expensive application
builds included Serein, the custom Helix fork, and Noctalia. Most ordinary
dependencies were downloaded from the existing official NixOS cache.

## Packaging and cache availability

Checked both the pinned nixpkgs revision `d4f25a3` and the current package index.

| Component | Finding | Practical implication |
| --- | --- | --- |
| Gaze 0.5.1 | No nixpkgs package found. Upstream maintains the Nix flake/module already used here; no advertised Nix binary cache found. | Keep the upstream integration; there is no verified cached replacement yet. |
| Serein | No nixpkgs package or advertised Nix binary cache found. Upstream Nix CI builds from source. | An external builder or CI using this flake could move compilation off the laptop. |
| Noctalia | nixpkgs has 5.4.1; this configuration uses the upstream 5.5.0 development version. | Using nixpkgs would avoid the custom shell build, but changes the version. |
| Noctalia greeter | nixpkgs and this configuration both report 1.7.0, but produce different store paths. | The nixpkgs package is a promising replacement after integration validation. |
| Helix | This configuration intentionally uses gj1118's fork. | The ordinary nixpkgs package would lose the fork's features; the upstream Helix cache is not a verified cache for this fork. |
| NVIDIA open module | Locally patched for PR 1299. | Expect a local module build when the kernel or driver changes until the upstream fix can replace the patch. |

Read-only HTTP metadata probes confirmed the exact nixpkgs Noctalia and greeter
outputs were present on `cache.nixos.org` (HTTP 200). The current upstream-flake
Noctalia and greeter outputs were absent from `noctalia.cachix.org`, and the
current fork's Helix output was absent from `helix.cachix.org` (HTTP 404). These
results describe the audit time; no binaries were downloaded or trusted.

## Options to consider

1. Prefer the nixpkgs Noctalia/greeter packages if their versions and behavior
   suit the user. This uses an already-trusted cache.
2. For development Noctalia, upstream provides a Cachix cache and a `cachix`
   branch that follows completed cache builds. Its documentation requires
   removing the Noctalia input's `nixpkgs.follows` to match its build inputs.
   This adds another nixpkgs dependency closure and another trusted signer.
3. For Gaze, Serein, and the Helix fork, build this exact flake on a trusted
   x86_64 Linux builder or CI and publish selected application outputs to a
   personal cache. Cache storage alone does not perform compilation: each new
   derivation still needs to be built somewhere. Uploading existing local
   results mainly helps restoration after garbage collection or another machine.

Only a matching derivation can be substituted. Updating a followed nixpkgs pin
can rebuild a custom application even if its own source did not change.

## Trust implications

A trusted cache key is not restricted to the advertised application's name.
Signatures authenticate a trusted signer, not a build's correspondence to its
source. Treat cache writers and CI credentials as part of the system's software
supply chain. Keep signature verification enabled and avoid adding local users
to `trusted-users` just to consume a cache; Nix documents that as equivalent to
root access.

Personal signing keeps the signing key outside Cachix, but the builder and key
still need protection. Managed signing also trusts Cachix's signing service.
Public cache contents are publicly readable; review outputs before uploading
system or Home Manager closures that contain personal configuration.

No package selections, input follows, substituters, or trust settings were
changed during this review.

## Sources

- [Gaze's upstream NixOS guide](https://gaze.gundulabs.com/guide/nixos)
- [Noctalia packaging and binary-cache instructions](https://docs.noctalia.dev/noctalia/getting-started/nixos/)
- [Cachix's cache explanation](https://docs.cachix.org/what-is-a-binary-cache)
- [Cachix's signing and trust model](https://docs.cachix.org/security)
- [Nix trust and signature settings](https://nix.dev/manual/nix/stable/command-ref/conf-file.html)
- [Nix remote builders](https://nix.dev/manual/nix/stable/advanced-topics/distributed-builds)
