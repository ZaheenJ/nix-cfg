{
  config,
  lib,
  pkgs,
  ...
}:
let
  routerUrl = "http://127.0.0.1:8080";
  billionContext = "npm:billion-context@0.1.178";
in
{
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = [ pkgs.nodejs ];
  };

  home.sessionVariables = {
    LLAMA_BASE_URL = routerUrl;
    ACP_AUTO_UPDATE = "0";
  };

  programs.nushell.extraEnv = ''
    $env.LLAMA_BASE_URL = "${routerUrl}"
    $env.ACP_AUTO_UPDATE = "0"
  '';

  # Pi updates settings.json for interactive choices, so merge the package entry.
  home.activation.piBillionContext = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    pi_settings_dir="${config.home.homeDirectory}/.pi/agent"
    pi_settings_file="$pi_settings_dir/settings.json"

    if [ -L "$pi_settings_file" ]; then
      echo "Cannot add ${billionContext}: Pi settings.json is a symlink" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$pi_settings_dir"
    pi_settings_temp="$(${pkgs.coreutils}/bin/mktemp "$pi_settings_file.XXXXXX")"

    if [ -f "$pi_settings_file" ]; then
      if ! ${pkgs.jq}/bin/jq -e --arg plugin "${billionContext}" '
        if type != "object" then error("Pi settings must be a JSON object")
        elif ((.packages // []) | type) != "array" then error("Pi packages must be an array")
        else
          .packages = (
            (.packages // [])
            | map(select(
                (if type == "string" then . elif type == "object" then (.source // "") else "" end
                | test("(^|[:/])billion-context(-pi)?(@|/|$)")) | not
              )) + [$plugin]
          )
        end
      ' "$pi_settings_file" > "$pi_settings_temp"; then
        ${pkgs.coreutils}/bin/rm "$pi_settings_temp"
        exit 1
      fi
      ${pkgs.coreutils}/bin/chmod --reference="$pi_settings_file" "$pi_settings_temp"
    else
      ${pkgs.jq}/bin/jq -n --arg plugin "${billionContext}" '{ packages: [$plugin] }' > "$pi_settings_temp"
      ${pkgs.coreutils}/bin/chmod 600 "$pi_settings_temp"
    fi

    if ${pkgs.coreutils}/bin/cmp -s "$pi_settings_temp" "$pi_settings_file"; then
      ${pkgs.coreutils}/bin/rm "$pi_settings_temp"
    else
      ${pkgs.coreutils}/bin/mv "$pi_settings_temp" "$pi_settings_file"
    fi
  '';
}
