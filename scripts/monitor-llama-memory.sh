#!/bin/sh
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf 'Usage: %s MODEL_ALIAS [LOG_FILE]\n' "$0" >&2
  exit 2
fi

model_alias=$1
log_file=${2:-/tmp/llama-memory-$(date +%Y%m%d-%H%M%S).log}

printf 'Waiting for model %s; output: %s\n' "$model_alias" "$log_file" >&2
while :; do
  model_pid=$(pgrep -fl llama-server | awk -v alias="$model_alias" '
    index($0, " --alias " alias " ") { print $1; exit }
  ')
  [ -n "$model_pid" ] && break
  sleep 2
done

{
  printf 'Model alias: %s\n' "$model_alias"
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
