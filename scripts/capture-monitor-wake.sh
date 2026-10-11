#!/usr/bin/env bash
set -uo pipefail
umask 077

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  printf 'Usage: bash %s [OUTPUT_PARENT]\nStart before plugging in the monitor. Run as your normal desktop user.\n' "$0"
  exit 0
fi
if (( $# > 1 || EUID == 0 )) || [[ ! -t 0 ]]; then
  printf 'Run in an interactive terminal as your normal desktop user, without sudo.\n' >&2
  exit 2
fi
for command in niri journalctl timeout mktemp; do
  if ! command -v "$command" >/dev/null; then
    printf 'Required command missing: %s\n' "$command" >&2
    exit 1
  fi
done

output_parent=${1:-${XDG_STATE_HOME:-$HOME/.local/state}/monitor-wake}
mkdir -p -- "$output_parent" || exit 1
output_parent=$(cd -- "$output_parent" && pwd -P) || exit 1
capture_dir=$(mktemp -d "$output_parent/$(date +%Y%m%d-%H%M%S)-XXXXXX") || exit 1
started_at=$(date --iso-8601=seconds)
background_pids=()
snapshot_number=0

record() {
  printf '\n$'
  printf ' %q' "$@"
  printf '\n'
  timeout --kill-after=2s 10s "$@"
  local status=$?
  if (( status != 0 )); then
    printf '[command exited %s; capture continues]\n' "$status"
  fi
  return 0
}

passive_state() {
  local card property path
  for card in /sys/class/drm/card[0-9]*; do
    [[ -e $card && ${card##*/} != *-* ]] || continue
    for property in runtime_status control runtime_suspended_time; do
      path="$card/device/power/$property"
      [[ -r $path ]] || continue
      printf '%s: ' "$path"
      cat -- "$path"
    done
  done
  for path in /sys/class/drm/card[0-9]*-*/status \
    /sys/class/drm/card[0-9]*-*/enabled; do
    [[ -r $path ]] || continue
    printf '%s: ' "$path"
    cat -- "$path"
  done
}

snapshot() {
  local label=$1 snapshot_dir
  snapshot_number=$((snapshot_number + 1))
  snapshot_dir="$capture_dir/$(printf '%02d' "$snapshot_number")-$label"
  mkdir -- "$snapshot_dir" || return 1
  printf '%s snapshot %s\n' "$(date --iso-8601=ns)" "$label" >> "$capture_dir/markers.log"
  {
    date --iso-8601=ns
    passive_state
    record niri msg outputs
    record niri msg --json outputs
    record free -h
    record cat /proc/pressure/memory
    local path
    for path in /proc/driver/nvidia/gpus/*/power; do
      [[ -r $path ]] && record cat "$path"
    done
  } > "$snapshot_dir/state.txt" 2>&1

  # Baseline stays passive. Checkpoint queries can wake a suspended NVIDIA GPU.
  if [[ $label != baseline ]] && command -v nvidia-smi >/dev/null; then
    {
      date --iso-8601=ns
      record nvidia-smi
      record nvidia-smi -q -d MEMORY,POWER,PERFORMANCE
    } > "$snapshot_dir/nvidia.txt" 2>&1
  fi
  printf 'Saved %s\n' "$snapshot_dir"
}

finish() {
  trap - EXIT INT TERM
  printf '%s capture stopped\n' "$(date --iso-8601=ns)" >> "$capture_dir/markers.log"
  local pid
  for pid in "${background_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pid in "${background_pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
  printf '\nCapture saved in:\n%s\n' "$capture_dir"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

{
  printf 'Started: %s\nCapture directory: %s\n' "$started_at" "$capture_dir"
  record uname -a
  record niri --version
  record cat /proc/cmdline /proc/sys/kernel/random/boot_id /proc/driver/nvidia/version
  record ls -l /sys/class/drm /run/current-system /run/booted-system
  record bash -c 'for path in /sys/module/nvidia*/parameters/*; do
    case "$path" in */modeset|*/fbdev|*/PreserveVideoMemoryAllocations|*/DynamicPowerManagement)
      printf "%s: " "$path"; cat "$path";; esac
  done'
} > "$capture_dir/system.txt" 2>&1

journalctl -b -k --since "$started_at" --follow --no-pager -o short-iso-precise \
  > "$capture_dir/kernel.log" 2>&1 &
background_pids+=("$!")

# Keep the complete messages from relevant desktop processes.
journalctl -b --user --since "$started_at" --follow --no-pager -o short-iso-precise \
  _COMM=niri + _COMM=kanshi + _SYSTEMD_USER_UNIT=power-watcher.service \
  > "$capture_dir/desktop.log" 2>&1 &
background_pids+=("$!")

if command -v udevadm >/dev/null; then
  udevadm monitor --kernel --udev --property --subsystem-match=drm \
    > "$capture_dir/drm-events.log" 2>&1 &
  background_pids+=("$!")
fi

(
  trap 'exit 0' TERM INT
  previous_outputs=''
  while :; do
    date --iso-8601=ns
    passive_state
    outputs=$(timeout --kill-after=1s 3s niri msg --json outputs 2>&1)
    if [[ $outputs != "$previous_outputs" ]]; then
      printf 'Outputs changed: %s\n' "$outputs"
      previous_outputs=$outputs
    fi
    sleep 2
  done
) > "$capture_dir/display-state.log" 2>&1 &
background_pids+=("$!")

snapshot baseline
printf '\nRecording to %s\n\n' "$capture_dir"
printf '%s\n' \
  '1. Plug the monitor in. Enter c once it is connected and working (or b if already broken).' \
  '2. Leave this running and let the displays turn off normally after ten minutes.' \
  '3. Wake them with the mouse. Before unplugging, enter b if artifacts appear.' \
  '' \
  'Commands (type a letter, then Enter):' \
  '  c  Capture connected/working state and NVIDIA memory usage.' \
  '  b  Mark artifacts and capture state and NVIDIA memory usage.' \
  '  s  Open the screenshot picker; select the external display and confirm.' \
  '  m  Save a timestamped note (connection type, observations, etc.).' \
  '  q  Finish. Logs are already on disk and survive a reboot.' \
  '' \
  'No sudo or rebuild needed. Screenshots may contain visible personal content.'

while IFS= read -r -p '> ' action; do
  case "$action" in
    c) snapshot connected ;;
    b) snapshot artifacts ;;
    s)
      screenshot_path="$capture_dir/screenshot-$(date +%Y%m%d-%H%M%S-%N).png"
      printf '%s screenshot requested: %s\n' "$(date --iso-8601=ns)" "$screenshot_path" >> "$capture_dir/markers.log"
      record niri msg action screenshot --path "$screenshot_path"
      ;;
    m)
      if IFS= read -r -p 'Note: ' note; then
        printf '%s note: %s\n' "$(date --iso-8601=ns)" "$note" >> "$capture_dir/markers.log"
      fi
      ;;
    q) break ;;
    *) printf 'Use c, b, s, m, or q, then Enter.\n' ;;
  esac
done
