# Package overrides and custom packages, applied as a nixpkgs overlay.
final: prev: {
  gaze = final.callPackage ../pkgs/gaze/package.nix { };
}
