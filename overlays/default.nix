# Package overrides and custom packages, applied as a nixpkgs overlay.
final: prev: {
  nushell = prev.nushell.overrideAttrs (old: {
    preBuild = (old.preBuild or "") + ''
      for reedline_dir in $(find "$NIX_BUILD_TOP" -maxdepth 4 -type d -name "reedline*" 2>/dev/null); do
        if [ -f "$reedline_dir/src/core_editor/editor.rs" ]; then
          echo "Patching reedline at $reedline_dir with PR 1192..."
          for f in "$reedline_dir"/src/prompt/base.rs "$reedline_dir"/src/core_editor/editor.rs; do
            tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
          done
          patch -p1 -d "$reedline_dir" < ${./reedline-1192.patch}
        fi
      done
    '';
  });
}
