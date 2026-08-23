#!/usr/bin/env bash
# Runs the renderer benchmark on macOS and prints one line per cell.
#
#   tool/bench.sh                       # full sweep, best of 2
#   BENCH_REPEAT=3 tool/bench.sh
#   BENCH_MODES=canvas,vertices BENCH_LOADS=100x100,500x500 tool/bench.sh
#
# The app window is brought to the front after launch: macOS throttles the
# frame rate of occluded windows, which otherwise silently cuts results by
# several times. The display is kept awake with caffeinate for the same
# reason. Leave the window in front and the machine idle while it runs.
set -euo pipefail
cd "$(dirname "$0")/.."

log=$(mktemp -t bench)
defines=(--dart-define=BENCH=true --dart-define=BENCH_REPEAT="${BENCH_REPEAT:-2}")
[[ -n "${BENCH_MODES:-}" ]] && defines+=(--dart-define=BENCH_MODES="$BENCH_MODES")
[[ -n "${BENCH_LOADS:-}" ]] && defines+=(--dart-define=BENCH_LOADS="$BENCH_LOADS")

caffeinate -dimsu flutter run --profile -d macos "${defines[@]}" >"$log" 2>&1 &
runner=$!
trap 'kill $runner 2>/dev/null || true' EXIT

until grep -qE "Flutter run key commands|Error|error:" "$log"; do sleep 2; done
if grep -qE "Error|error:" "$log"; then cat "$log"; exit 1; fi
open build/macos/Build/Products/Profile/bouncy_ball_physics.app

until grep -qE "BENCH done|Lost connection|Exception" "$log"; do sleep 5; done
grep -E "^flutter: BENCH mode" "$log" | sort -u | sed 's/^flutter: BENCH //'
