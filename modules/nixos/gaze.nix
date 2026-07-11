# gaze: facial-authentication daemon + PAM integration (host-agnostic module).
# The package is provided via the overlay (pkgs.gaze). Enabling this runs the
# gazed system daemon; face auth is only wired into PAM for the services listed
# in `pamServices` (empty by default, so enabling the daemon alone is safe and
# lets you validate enrollment via `gaze doctor` / `gaze add-face` first).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.gaze;
  # Rebuild the package with the configured PAM auth timeout.
  pkg = cfg.package.override { inherit (cfg) authTimeoutSecs; };
  settingsFormat = pkgs.formats.toml { };

  sec = cfg.settings.security or { };
  cams = cfg.settings.cameras or { };

  # Upstream enum constraints (gaze-core/src/config.rs).
  levels = [
    "low"
    "medium"
    "high"
    "maximum"
    "custom"
  ];
  qualities = [
    "standard"
    "accurate"
  ];
  hybridPolicies = [
    "default"
    "or"
    "fallback_on_dark"
    "and"
  ];
  # A field is "unset" when absent or the empty string (gaze treats "" as default).
  isEnum =
    attrs: name: allowed:
    !(attrs ? ${name}) || attrs.${name} == "" || lib.elem attrs.${name} allowed;
in
{
  options.services.gaze = {
    enable = lib.mkEnableOption "gaze facial authentication daemon";

    package = lib.mkPackageOption pkgs "gaze" { };

    authTimeoutSecs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12;
      description = ''
        Seconds the PAM module waits for a face match before giving up and
        falling through to the password prompt. Lower values fall back to the
        password faster when a face isn't recognized.
      '';
    };

    pamServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "sudo"
        "login"
        "greetd"
      ];
      description = ''
        PAM service names to enable gaze face authentication for. gaze is
        inserted just before the password module with control `sufficient`, so
        a face match completes authentication and any other outcome falls
        through to the password prompt.

        Leave empty to run the daemon without touching PAM (useful for
        validating enrollment with `gaze doctor` / `gaze add-face` first).
      '';
    };

    logLevel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "info,gaze_core=debug,gazed=debug";
      description = ''
        Value for the daemon's `RUST_LOG` environment variable. `null` leaves
        it unset (gaze's built-in default). Useful for diagnosing camera,
        matching, or liveness problems in `journalctl -u gazed`.
      '';
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          security.level = "high";
          cameras = {
            rgb = "v4l2src device=/dev/video0";
            ir = "v4l2src device=/dev/video2";
          };
          liveness.enabled = true;
        }
      '';
      description = ''
        Configuration written to {file}`/etc/gaze/config.toml`. Every field has
        an upstream default, so only overrides need to be set. Keys (see
        <https://github.com/GunduLabs/gaze>):

        - `security.level`: one of `low`, `medium`, `high`, `maximum`, `custom`.
        - `security.detector` / `security.recognizer` (custom level): `standard`
          or `accurate`. `security.threshold`: float. `security.hybrid_policy`:
          one of `default`, `or`, `fallback_on_dark`, `and`.
        - `cameras.rgb` / `cameras.ir`: `"primary"` (PipeWire) or a GStreamer
          source. NOTE: gazed runs as root with no user PipeWire session, so on
          most systems these must be direct V4L2 sources, e.g.
          `"v4l2src device=/dev/video0"`.
        - `cameras.emitter_enabled` (bool), `cameras.dark_luma_threshold` (0-255).
        - `auth.abort_if_ssh` / `auth.abort_if_lid_closed` /
          `auth.require_confirmation` (bool), `auth.resume_grace_ms` (int).
        - `enrollment.max_templates` (int).
        - `liveness.enabled` (bool), `liveness.threshold` (float),
          `liveness.max_frames` (int).
        - `storage.encrypt_templates` (bool; needs a TPM 2.0).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isEnum sec "level" levels;
        message = "services.gaze.settings.security.level must be one of: ${lib.concatStringsSep ", " levels}.";
      }
      {
        assertion = isEnum sec "detector" qualities;
        message = "services.gaze.settings.security.detector must be one of: ${lib.concatStringsSep ", " qualities}.";
      }
      {
        assertion = isEnum sec "recognizer" qualities;
        message = "services.gaze.settings.security.recognizer must be one of: ${lib.concatStringsSep ", " qualities}.";
      }
      {
        assertion = isEnum sec "hybrid_policy" hybridPolicies;
        message = "services.gaze.settings.security.hybrid_policy must be one of: ${lib.concatStringsSep ", " hybridPolicies}.";
      }
    ];

    # The root daemon can't reach a user PipeWire session (and none exists at the
    # greeter/lock screen), so "primary"/pipewiresrc won't work there.
    warnings = lib.optional (cfg.pamServices != [ ] && (cams.rgb or "primary") == "primary") ''
      services.gaze.settings.cameras.rgb is "primary" (PipeWire), but gazed runs
      as root and cannot use a user PipeWire session — PAM face auth will fail to
      open the camera. Set it to a direct V4L2 source, e.g.
      "v4l2src device=/dev/video0".
    '';

    environment.systemPackages = [ pkg ];
    environment.etc."gaze/config.toml".source = settingsFormat.generate "gaze-config.toml" cfg.settings;

    # System-bus policy for com.gundulabs.Gaze (shipped in the package).
    services.dbus.packages = [ pkg ];

    # Hardened daemon, translated from the upstream gazed.service. Runs as root
    # (needs camera + TPM + IR-emitter ioctl); models download into the state /
    # cache dirs on first enrollment.
    systemd.services.gazed = {
      description = "Gaze facial-authentication daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "dbus.service" ];
      requires = [ "dbus.service" ];
      environment = lib.mkIf (cfg.logLevel != null) { RUST_LOG = cfg.logLevel; };
      serviceConfig = {
        ExecStart = lib.getExe' pkg "gazed";
        Restart = "on-failure";
        RestartSec = 5;
        StateDirectory = "gaze"; # /var/lib/gaze (enrollments + models)
        StateDirectoryMode = "0700";
        CacheDirectory = "gaze"; # /var/cache/gaze (liveness model)
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        InaccessiblePaths = [
          "/home"
          "/root"
        ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
        # IR cameras are driven directly via V4L2 and need their /dev/video*
        # node; /dev is left intact (no PrivateDevices) and video group added.
        SupplementaryGroups = [ "video" ];
      };
    };

    security.pam.services = lib.genAttrs cfg.pamServices (name: {
      rules.auth.gaze = {
        # Just before the unix/password module so a face match short-circuits.
        order = config.security.pam.services.${name}.rules.auth.unix.order - 10;
        # "sufficient" = on success, auth is done; on failure, fall through to
        # the password. (Upstream's pam-config uses [success=end …], but `end`
        # is a pam-auth-update abstraction, not a valid literal PAM action.)
        control = "sufficient";
        modulePath = "${pkg}/lib/security/pam_gaze.so";
      };
    });
  };
}
