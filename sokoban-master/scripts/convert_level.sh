#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/sokoban_level_convert.py"

if [[ $# -ne 1 ]]; then
  cat <<'USAGE'
Usage:
  ./sokoban-master/scripts/convert_level.sh <input.json|input.pddl>

Rules:
  - JSON output is always written to: sokoban-master/config/<name>.json
  - PDDL output is always written to: pddl/sokoban/pb_json/<name>.pddl
  - Output basename is always the same as input basename.
USAGE
  exit 1
fi

if [[ ! -f "$PY_SCRIPT" ]]; then
  echo "Error: missing converter script: $PY_SCRIPT" >&2
  exit 1
fi

python3 "$PY_SCRIPT" "$1"
