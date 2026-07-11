# gaze: facial-authentication daemon + CLI + PAM module (GunduLabs/gaze).
# We build only the daemon (gazed), the CLI (gaze), and the sequential PAM
# module (pam-gaze -> libpam_gaze.so); the GTK GUI (gaze-gui) and the
# "grosshack" simultaneous PAM variant are skipped.
#
# ONNX Runtime: the `ort` crate would download a prebuilt runtime, which the
# Nix sandbox forbids, so we point it at nixpkgs' onnxruntime (system strategy,
# dynamic link). Models themselves are downloaded by gazed at first enrollment
# into its StateDirectory (/var/lib/gaze) — not a build-time concern.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  clang,
  opencv,
  onnxruntime,
  tpm2-tss,
  openssl,
  gst_all_1,
  glib,
  # Seconds the PAM module waits for the daemon to verify a face before giving
  # up and falling through to the password. Upstream hardcodes 12; patched here
  # so it can be tuned (there is no runtime config option for it).
  authTimeoutSecs ? 12,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gaze";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "GunduLabs";
    repo = "gaze";
    tag = "v${finalAttrs.version}";
    hash = "sha256-UFEIc/UCv7kezogEAwSn6oMdhtIMwBB77GsmbPvXiPo=";
  };

  cargoHash = "sha256-nZJomihL1RETBMPx4qzqY1bTj3BZSiVEs8tA96pEsgM=";

  postPatch = ''
    substituteInPlace pam-gaze-core/src/lib.rs \
      --replace-fail "CAMERA_AUTH_TIMEOUT_SECS: u64 = 12" \
                     "CAMERA_AUTH_TIMEOUT_SECS: u64 = ${toString authTimeoutSecs}"
  '';

  # Build only the crates we ship (skips gaze-gui / pam-gaze-grosshack).
  cargoBuildFlags = [
    "--package=gaze"
    "--package=gaze-cli"
    "--package=pam-gaze"
  ];

  # Tests exercise the camera / detection pipeline, which isn't available in the
  # sandbox. Revisit once we know which are pure.
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook # libclang for the opencv + tss-esapi bindgen
    clang # opencv-binding-generator shells out to the clang binary
    makeWrapper
  ];

  buildInputs = [
    opencv
    onnxruntime
    tpm2-tss
    openssl # openssl-sys, pulled in by the model-download HTTP stack
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base # libgstapp / libgstvideo for gstreamer-app/-video
  ];

  env = {
    ORT_STRATEGY = "system";
    ORT_LIB_LOCATION = "${lib.getLib onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";
  };

  postInstall = ''
    # PAM module: buildRustPackage auto-installs the cdylib to $out/lib; move it
    # to where PAM looks (and where the NixOS module references it).
    install -Dm755 $releaseDir/libpam_gaze.so $out/lib/security/pam_gaze.so
    rm -f $out/lib/libpam_gaze.so

    # Ship the upstream integration assets for the NixOS module to consume.
    install -Dm644 packaging/config/config.toml            $out/share/gaze/config.toml
    install -Dm644 packaging/config/gazed.service          $out/share/gaze/gazed.service
    install -Dm644 packaging/config/com.gundulabs.Gaze.conf $out/share/dbus-1/system.d/com.gundulabs.Gaze.conf
    install -Dm644 packaging/config/com.gundulabs.gaze.policy $out/share/polkit-1/actions/com.gundulabs.gaze.policy
    install -Dm644 packaging/pam/gaze                       $out/share/gaze/pam/gaze
  '';

  # gazed dlopens gstreamer plugins (v4l2src etc.) at runtime; point it at them.
  postFixup = ''
    wrapProgram $out/bin/gazed \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${
        lib.makeSearchPath "lib/gstreamer-1.0" [
          gst_all_1.gstreamer.out # core plugins (typefind, capsfilter) live in .out, not the default output
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good # v4l2src + jpegdec for direct-V4L2 cameras
        ]
      }"
  '';

  meta = {
    description = "Facial authentication for Linux (daemon, CLI, and PAM module)";
    homepage = "https://github.com/GunduLabs/gaze";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "gaze";
  };
})
