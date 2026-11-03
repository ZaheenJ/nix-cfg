{
  pkgs,
  piPackageDir ? null,
}:
let
  inherit (pkgs) lib;
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
in
{
  cloud-ai-settings = pkgs.runCommandLocal "check-cloud-ai-settings" { } ''
    ${python}/bin/python3 -B ${../home/profiles/cloud-ai-tools}/test_merge_settings.py
    touch $out
  '';

  nushell-config =
    pkgs.runCommandLocal "check-nushell-config" { nativeBuildInputs = [ pkgs.nushell ]; }
      ''
        export HOME=$(mktemp -d)
        rc=0
        check_nushell() {
          local msg
          msg=$(nu --no-config-file --no-std-lib -c "$2" 2>&1 >/dev/null) || rc=1
          if [ -n "$msg" ]; then
            echo "### $1"; echo "$msg"; echo; rc=1
          fi
        }
        # Source parses command definitions without executing their bodies.
        for f in ${../home/common/nushell}/*.nu ${../home/profiles/music}/*.nu; do
          check_nushell "$f" "let abbreviations = {}; source $f"
        done
        check_nushell "abbreviation menu" \
          "let abbreviations = {g: 'git', gs: 'git status'}; source ${../home/common/nushell/config.nu}; source ${./nushell-menu.nu}"
        if [ $rc -ne 0 ]; then
          echo "nushell config check failed — fix the deprecations/errors above." >&2
          exit 1
        fi
        touch $out
      '';

  fish-config = pkgs.runCommandLocal "check-fish-config" { nativeBuildInputs = [ pkgs.fish ]; } ''
    rc=0
    for f in ${../home/common/fish}/*.fish; do
      if ! fish -n "$f"; then echo "### $f failed fish -n"; rc=1; fi
    done
    if [ $rc -ne 0 ]; then
      echo "fish config check failed — fix the syntax errors above." >&2
      exit 1
    fi
    touch $out
  '';
}
// lib.optionalAttrs (piPackageDir != null) {
  pi-output-budget =
    pkgs.runCommandLocal "check-pi-output-budget" { nativeBuildInputs = [ pkgs.nodejs ]; }
      ''
        export HOME=$(mktemp -d)
        export BILI_PACKAGE_DIR=${lib.escapeShellArg piPackageDir}
        node --test ${../pkgs/pi-extensions}/output-budget*.test.mjs
        touch $out
      '';
}
