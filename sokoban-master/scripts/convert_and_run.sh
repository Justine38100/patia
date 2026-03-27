#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOKOBAN_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd -- "$SOKOBAN_DIR/.." && pwd)"

CONVERT_SCRIPT="$SCRIPT_DIR/convert_level.sh"
RUN_SCRIPT="$SCRIPT_DIR/run_pddl_to_sokoban.sh"
DEFAULT_DOMAIN="$REPO_ROOT/pddl/sokoban/domain.pddl"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/convert_and_run.sh 1 <input.json|input.pddl> <timeout_sec> <heuristic_id> [domain.pddl]
  ./scripts/convert_and_run.sh 2 <input.json|input.pddl> <timeout_sec> [domain.pddl]

Examples (from sokoban-master):
  ./scripts/convert_and_run.sh 1 config/test21.json 60 5
  ./scripts/convert_and_run.sh 1 ../pddl/sokoban/pb_json/test21.pddl 60 5
  ./scripts/convert_and_run.sh 2 config/test_pddl_custom.json 60

Behavior:
  - Convert level in the opposite format (JSON <-> PDDL)
  - Ensure JSON testcase exists in sokoban-master/config/<name>.json
  - Launch planner + converter + Java visualizer in one command
USAGE
}

resolve_existing_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    if [[ "$path" == /* ]]; then
      printf '%s\n' "$path"
    else
      printf '%s\n' "$PWD/$path"
    fi
    return 0
  fi

  if [[ -f "$REPO_ROOT/$path" ]]; then
    printf '%s\n' "$REPO_ROOT/$path"
    return 0
  fi

  if [[ -f "$SOKOBAN_DIR/$path" ]]; then
    printf '%s\n' "$SOKOBAN_DIR/$path"
    return 0
  fi

  return 1
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

planner="$1"
input_raw="$2"
timeout_sec="$3"

if [[ ! "$timeout_sec" =~ ^[0-9]+$ ]]; then
  echo "Error: timeout_sec must be a positive integer." >&2
  exit 1
fi

heuristic_id=""
domain_file="$DEFAULT_DOMAIN"

case "$planner" in
  1)
    if [[ $# -lt 4 ]]; then
      echo "Error: heuristic_id is required for planner 1 (HSP)." >&2
      usage
      exit 1
    fi
    heuristic_id="$4"
    if [[ $# -ge 5 ]]; then
      domain_file="$5"
    fi
    ;;
  2)
    if [[ $# -ge 4 ]]; then
      domain_file="$4"
    fi
    ;;
  *)
    echo "Error: planner must be 1 (HSP) or 2 (FF)." >&2
    usage
    exit 1
    ;;
esac

if [[ ! -f "$CONVERT_SCRIPT" ]]; then
  echo "Error: missing script: $CONVERT_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$RUN_SCRIPT" ]]; then
  echo "Error: missing script: $RUN_SCRIPT" >&2
  exit 1
fi

input_file="$(resolve_existing_file "$input_raw")" || {
  echo "Error: input file not found: $input_raw" >&2
  exit 1
}

domain_file="$(resolve_existing_file "$domain_file")" || {
  echo "Error: domain file not found: $domain_file" >&2
  exit 1
}

ext="${input_file##*.}"
ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"
stem="$(basename "${input_file%.*}")"

testcase_json="$SOKOBAN_DIR/config/${stem}.json"

case "$ext" in
  json)
    echo "[1/3] Convert JSON -> PDDL"
    problem_file="$("$CONVERT_SCRIPT" "$input_file")"

    # Ensure testcase is available in sokoban-master/config/<name>.json
    if [[ "$input_file" != "$testcase_json" ]]; then
      cp "$input_file" "$testcase_json"
    fi
    ;;

  pddl)
    echo "[1/3] Convert PDDL -> JSON"
    "$CONVERT_SCRIPT" "$input_file" >/dev/null
    problem_file="$input_file"
    ;;

  *)
    echo "Error: input file must end with .json or .pddl" >&2
    exit 1
    ;;
esac

testcase_name="${stem}.json"

echo "[2/3] Run planner + URDL conversion"
echo "[3/3] Launch Java visualizer"

if [[ "$planner" == "1" ]]; then
  "$RUN_SCRIPT" 1 "$domain_file" "$problem_file" "$timeout_sec" "$heuristic_id" "$testcase_name"
else
  "$RUN_SCRIPT" 2 "$domain_file" "$problem_file" "$timeout_sec" "$testcase_name"
fi
