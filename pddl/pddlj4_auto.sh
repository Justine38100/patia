#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
JAR="$SCRIPT_DIR/pddl4j-4.0.0.jar"

if [[ ! -f "$JAR" ]]; then
  echo "Error: jar not found: $JAR"
  exit 1
fi

show_usage() {
  cat <<'USAGE'
Usage:
  ./pddlj4_auto.sh 1 <domain.pddl> <problem.pddl> <timeout_sec> <heuristic_id>
  ./pddlj4_auto.sh 2 <domain.pddl> <problem.pddl> <timeout_sec>

Planner choice:
  1 -> HSP
  2 -> FF

Heuristic id for HSP:
  0 AJUSTED_SUM
  1 AJUSTED_SUM2
  2 AJUSTED_SUM2M
  3 COMBO
  4 MAX
  5 FAST_FORWARD
  6 SET_LEVEL
  7 SUM
  8 SUM_MUTEX
USAGE
}

if [[ $# -lt 4 ]]; then
  show_usage
  exit 1
fi

choice="$1"
domain_file="$2"
problem_file="$3"
timeout_sec="$4"
heuristic_id="${5:-}"

if [[ ! -f "$domain_file" ]]; then
  echo "Error: domain file not found: $domain_file"
  exit 1
fi

if [[ ! -f "$problem_file" ]]; then
  echo "Error: problem file not found: $problem_file"
  exit 1
fi

if [[ ! "$timeout_sec" =~ ^[0-9]+$ ]]; then
  echo "Error: timeout must be a positive integer"
  exit 1
fi

case "$choice" in
  1)
    if [[ -z "$heuristic_id" ]]; then
      echo "Error: heuristic_id is required for HSP"
      show_usage
      exit 1
    fi

    case "$heuristic_id" in
      0) heuristic='AJUSTED_SUM' ;;
      1) heuristic='AJUSTED_SUM2' ;;
      2) heuristic='AJUSTED_SUM2M' ;;
      3) heuristic='COMBO' ;;
      4) heuristic='MAX' ;;
      5) heuristic='FAST_FORWARD' ;;
      6) heuristic='SET_LEVEL' ;;
      7) heuristic='SUM' ;;
      8) heuristic='SUM_MUTEX' ;;
      *)
        echo "Error: invalid heuristic_id '$heuristic_id' (expected 0..8)"
        show_usage
        exit 1
        ;;
    esac

    exec java -cp "$JAR" -server -Xms2048m -Xmx2048m \
      fr.uga.pddl4j.planners.statespace.HSP \
      "$domain_file" "$problem_file" -t "$timeout_sec" -e "$heuristic"
    ;;

  2)
    exec java -cp "$JAR" -server -Xms2048m -Xmx2048m \
      fr.uga.pddl4j.planners.statespace.FF \
      "$domain_file" "$problem_file" -t "$timeout_sec"
    ;;

  *)
    echo "Error: choice must be 1 (HSP) or 2 (FF)"
    show_usage
    exit 1
    ;;
esac
