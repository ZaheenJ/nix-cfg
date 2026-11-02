case "${1-}" in
  install|update|remove|uninstall|config)
    printf '%s\n' "pi $1 is disabled in the sandbox. Edit the Nix package manifest and rebuild the Home Manager configuration instead." >&2
    exit 2
    ;;
esac

cwd=$(pwd -P)
case "$cwd" in
  /|/run|/run/*|/nix|/nix/*|/etc|/etc/*|/usr|/usr/*|/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/lib64|/lib64/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*|/boot|/boot/*|/var|/var/*|/root|/root/*|/snap|/snap/*|/lost+found|/lost+found/*)
    printf 'Refusing to run pi from protected system directory: %s\n' "$cwd" >&2
    exit 2
    ;;
esac

if ! sockets=$(find "$cwd" -type s -print -quit); then
  printf 'Could not safely inspect sockets under %s; refusing to run pi.\n' "$cwd" >&2
  exit 2
fi
if [ -n "$sockets" ]; then
  printf 'Refusing to run pi because the workspace contains a Unix socket: %s\n' "$sockets" >&2
  exit 2
fi

workspace_hash=$(printf '%s' "$cwd" | sha256sum)
workspace_hash=${workspace_hash%% *}
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
tunnel_socket="$runtime_dir/pi-llama/llama.sock"

systemctl --user start pi-llama-tunnel.service
ready=0
for ((attempt = 0; attempt < 30; attempt++)); do
  if curl --silent --show-error --fail --noproxy '*' --max-time 1 \
    --unix-socket "$tunnel_socket" http://localhost/models >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [ "$ready" -ne 1 ]; then
  printf 'The local llama tunnel did not become ready within 30 seconds.\n' >&2
  exit 1
fi

if [ -L /tmp/pi ]; then
  printf '%s\n' 'Refusing to use a symlink at /tmp/pi.' >&2
  exit 2
fi
install -d -m 0700 /tmp/pi
if [ "$(stat -c %u /tmp/pi)" -ne "$(id -u)" ]; then
  printf '%s\n' 'Refusing to use /tmp/pi because it is owned by another user.' >&2
  exit 2
fi
temp_dir=$(mktemp -d /tmp/pi/pi.XXXXXXXXXX)
mkdir -m 0700 "$temp_dir/runtime"
cleanup() {
  rm -rf -- "$temp_dir"
}
trap cleanup EXIT HUP INT TERM

bwrap \
  --unshare-user --unshare-net --unshare-pid --unshare-ipc --unshare-uts \
  --disable-userns --die-with-parent --clearenv \
  --dir /run \
  --dir /run/current-system \
  --ro-bind /nix/store /nix/store \
  --ro-bind /etc /etc \
  --ro-bind /usr /usr \
  --ro-bind /bin /bin \
  --ro-bind /lib64 /lib64 \
  --ro-bind /run/current-system/sw /run/current-system/sw \
  --proc /proc \
  --dev /dev \
  --dir /workspace \
  --dir "/workspace/$workspace_hash" \
  --bind "$cwd" "/workspace/$workspace_hash" \
  --chdir "/workspace/$workspace_hash" \
  --dir /home \
  --bind "$state_dir" /home/pi \
  --ro-bind "$runtime_dir/pi-llama" /run/pi-model \
  --bind "$temp_dir" /tmp \
  --setenv HOME /home/pi \
  --setenv PI_CODING_AGENT_DIR /home/pi/.pi/agent \
  --setenv LLAMA_BASE_URL http://127.0.0.1:8080 \
  --setenv ACP_AUTO_UPDATE 0 \
  --setenv PI_SKIP_VERSION_CHECK 1 \
  --setenv PI_TELEMETRY 0 \
  --setenv SHELL /bin/sh \
  --setenv TERM "${TERM:-xterm-256color}" \
  --setenv LANG "${LANG:-C.UTF-8}" \
  --setenv PATH "$inner_path" \
  --setenv XDG_RUNTIME_DIR /tmp/runtime \
  -- "$pi_inner" "$@"
