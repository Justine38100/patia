#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/pddl_plan_to_urdl.sh <planner_output.txt|-> [solution.txt]

Examples:
  ./scripts/pddl_plan_to_urdl.sh /tmp/plan.log
  ./scripts/pddl_plan_to_urdl.sh /tmp/plan.log config/solution.txt
  ./pddl/pddlj4_auto.sh 1 pddl/sokoban/domain.pddl pddl/sokoban/problem.pddl 60 5 | \
    ./sokoban-master/scripts/pddl_plan_to_urdl.sh - sokoban-master/config/solution.txt
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

input="$1"
output="${2:-}"

if [[ "$input" != "-" && ! -f "$input" ]]; then
  echo "Error: input file not found: $input" >&2
  exit 1
fi

moves=""
count=0

while IFS= read -r action; do
  [[ -z "$action" ]] && continue
  count=$((count + 1))
  action_lc="$(printf '%s' "$action" | tr '[:upper:]' '[:lower:]')"
  case "$action_lc" in
    *north) moves+="U" ;;
    *east)  moves+="R" ;;
    *south) moves+="D" ;;
    *west)  moves+="L" ;;
    *)
      echo "Error: unsupported action '$action' (need direction in action name)." >&2
      exit 2
      ;;
  esac
done < <(
  if [[ "$input" == "-" ]]; then
    cat
  else
    cat "$input"
  fi | grep -E '^[[:space:]]*[0-9]+:' | sed -E 's/.*\([[:space:]]*([A-Za-z0-9_-]+).*/\1/'
)

if [[ "$count" -eq 0 ]]; then
  echo "Error: no plan actions found in input." >&2
  exit 3
fi

if [[ -n "$output" ]]; then
  printf '%s\n' "$moves" > "$output"
  echo "Saved $count actions as URDL sequence to: $output"
else
  printf '%s\n' "$moves"
fi
