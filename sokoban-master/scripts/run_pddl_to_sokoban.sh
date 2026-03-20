#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOKOBAN_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd -- "$SOKOBAN_DIR/.." && pwd)"

PDDL_SCRIPT="$REPO_ROOT/pddl/pddlj4_auto.sh"
CONVERTER_SCRIPT="$SCRIPT_DIR/pddl_plan_to_urdl.sh"
PDDL4J_JAR="$REPO_ROOT/pddl/pddl4j-4.0.0.jar"

PLAN_LOG="${PLAN_LOG:-$SOKOBAN_DIR/config/plan.log}"
SOLUTION_FILE="${SOLUTION_FILE:-$SOKOBAN_DIR/config/solution.txt}"
DEFAULT_TESTCASE="${SOKOBAN_TESTCASE:-test21.json}"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/run_pddl_to_sokoban.sh 1 <domain.pddl> <problem.pddl> <timeout_sec> <heuristic_id> [testcase.json]
  ./scripts/run_pddl_to_sokoban.sh 2 <domain.pddl> <problem.pddl> <timeout_sec> [testcase.json]

Examples:
  ./scripts/run_pddl_to_sokoban.sh 1 pddl/sokoban/domain.pddl pddl/sokoban/problem.pddl 60 5
  ./scripts/run_pddl_to_sokoban.sh 2 pddl/sokoban/domain.pddl pddl/sokoban/problem.pddl 60 test21.json

Optional environment variables:
  PLAN_LOG=/path/to/plan.log
  SOLUTION_FILE=/path/to/solution.txt
  SOKOBAN_TESTCASE=test21.json
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

  return 1
}

if [[ $# -lt 4 ]]; then
  usage
  exit 1
fi

planner="$1"
domain_input="$2"
problem_input="$3"
timeout_sec="$4"

if [[ ! "$timeout_sec" =~ ^[0-9]+$ ]]; then
  echo "Error: timeout_sec must be a positive integer." >&2
  exit 1
fi

heuristic_id=""
testcase="$DEFAULT_TESTCASE"

case "$planner" in
  1)
    if [[ $# -lt 5 ]]; then
      echo "Error: heuristic_id is required when planner is 1 (HSP)." >&2
      usage
      exit 1
    fi
    heuristic_id="$5"
    if [[ $# -ge 6 ]]; then
      testcase="$6"
    fi
    ;;
  2)
    if [[ $# -ge 5 ]]; then
      testcase="$5"
    fi
    ;;
  *)
    echo "Error: planner must be 1 (HSP) or 2 (FF)." >&2
    usage
    exit 1
    ;;
esac

domain_file="$(resolve_existing_file "$domain_input")" || {
  echo "Error: domain file not found: $domain_input" >&2
  exit 1
}

problem_file="$(resolve_existing_file "$problem_input")" || {
  echo "Error: problem file not found: $problem_input" >&2
  exit 1
}

if [[ ! -f "$PDDL_SCRIPT" ]]; then
  echo "Error: missing planner script: $PDDL_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$CONVERTER_SCRIPT" ]]; then
  echo "Error: missing converter script: $CONVERTER_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$PDDL4J_JAR" ]]; then
  echo "Error: missing jar: $PDDL4J_JAR" >&2
  exit 1
fi

mkdir -p "$(dirname "$PLAN_LOG")" "$(dirname "$SOLUTION_FILE")"

echo "[1/5] Solve PDDL problem..."
if [[ "$planner" == "1" ]]; then
  bash "$PDDL_SCRIPT" "$planner" "$domain_file" "$problem_file" "$timeout_sec" "$heuristic_id" > "$PLAN_LOG"
else
  bash "$PDDL_SCRIPT" "$planner" "$domain_file" "$problem_file" "$timeout_sec" > "$PLAN_LOG"
fi

echo "[2/5] Convert planner output to URDL..."
bash "$CONVERTER_SCRIPT" "$PLAN_LOG" "$SOLUTION_FILE"

echo "[3/5] Ensure Maven can resolve pddl4j..."
cd "$SOKOBAN_DIR"
mvn -q install:install-file \
  -Dfile="$PDDL4J_JAR" \
  -DgroupId=fr.uga \
  -DartifactId=pddl4j \
  -Dversion=4.0.0 \
  -Dpackaging=jar \
  -DgeneratePom=true

echo "[4/5] Compile Java project..."
mvn -q -DskipTests compile

echo "[5/5] Run visualizer..."
echo "    testcase: $testcase"
echo "    solution: $SOLUTION_FILE"

java --add-opens java.base/java.lang=ALL-UNNAMED \
  -server -Xms2048m -Xmx2048m \
  -Dsolution.file="$SOLUTION_FILE" \
  -Dsokoban.testcase="$testcase" \
  -cp "$(mvn dependency:build-classpath -Dmdep.outputFile=/dev/stdout -q):target/test-classes/:target/classes" \
  sokoban.SokobanMain
