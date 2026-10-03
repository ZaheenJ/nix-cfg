#!/bin/sh
set -eu

log_file=${1:-/tmp/llama-memory-$(date +%Y%m%d-%H%M%S).log}
model_pattern='llama-server.*--alias unsloth/Qwen3.8-27B-GGUF:IQ4_XS'

printf 'Waiting for the 27B model process; output: %s\n' "$log_file" >&2
while :; do
  model_pid=$(pgrep -f "$model_pattern" | awk 'NR == 1 { print; exit }')
  [ -n "$model_pid" ] && break
  sleep 2
done

{
  printf 'Model PID: %s\n' "$model_pid"
  vm_stat | awk 'NR == 1'
  while kill -0 "$model_pid" 2>/dev/null; do
    printf '\n%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    memory_pressure -Q | awk '/System-wide memory free percentage/'
    vm_stat | awk '/^Pages wired down:|^Pages occupied by compressor:|^Swapins:|^Swapouts:/'
    footprint --swapped --wired -p "$model_pid" |
      awk '/Footprint:|^  Dirty|TOTAL|phys_footprint/'
    sleep 15
  done
} | tee "$log_file"
