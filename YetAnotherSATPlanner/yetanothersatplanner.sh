#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

MAIN_CLASS="fr.uga.pddl4j.yasp.YetAnotherSATPlanner"
JARS_CP="$PROJECT_DIR/lib/pddl4j-4.0.0.jar:$PROJECT_DIR/lib/org.sat4j.core.jar"
RUN_CP="$PROJECT_DIR/classes:$JARS_CP"

DO_COMPILE=1
JAVA_XMS="1024m"
JAVA_XMX="2048m"

usage() {
  cat <<'USAGE'
Usage:
  ./yetanothersatplanner.sh [options] <domain.pddl> <problem.pddl>
  ./yetanothersatplanner.sh --compile-only

Options:
  --no-compile      N'effectue pas la compilation avant execution
  --compile-only    Compile uniquement puis quitte
  --xms <size>      Memoire initiale JVM (defaut: 1024m)
  --xmx <size>      Memoire max JVM (defaut: 2048m)
  -h, --help        Affiche cette aide

Exemples:
  ./yetanothersatplanner.sh domain.pddl p01.pddl
  ./yetanothersatplanner.sh ../pddl/sokoban/domain.pddl ../pddl/sokoban/pb_json/test21.pddl
  ./yetanothersatplanner.sh --no-compile ../pddl/hanoi/domaine.pddl ../pddl/hanoi/problem3_3.pddl
USAGE
}

compile() {
  echo "[INFO] Compilation Java..."
  mkdir -p "$PROJECT_DIR/classes"
  javac -J-Djava.net.useSystemProxies=true -d "$PROJECT_DIR/classes" -cp "$JARS_CP" "$PROJECT_DIR"/src/fr/uga/pddl4j/yasp/*.java
}

resolve_file() {
  local input="$1"

  if [[ -f "$input" ]]; then
    printf "%s" "$input"
    return 0
  fi

  if [[ -f "$PROJECT_DIR/$input" ]]; then
    printf "%s" "$PROJECT_DIR/$input"
    return 0
  fi

  if [[ -f "$PROJECT_DIR/../$input" ]]; then
    printf "%s" "$PROJECT_DIR/../$input"
    return 0
  fi

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-compile)
      DO_COMPILE=0
      shift
      ;;
    --compile-only)
      compile
      echo "[OK] Compilation terminee."
      exit 0
      ;;
    --xms)
      JAVA_XMS="${2:-}"
      if [[ -z "$JAVA_XMS" ]]; then
        echo "[ERREUR] Valeur manquante pour --xms"
        exit 1
      fi
      shift 2
      ;;
    --xmx)
      JAVA_XMX="${2:-}"
      if [[ -z "$JAVA_XMX" ]]; then
        echo "[ERREUR] Valeur manquante pour --xmx"
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

DOMAIN_RAW="$1"
PROBLEM_RAW="$2"

if ! DOMAIN_FILE="$(resolve_file "$DOMAIN_RAW")"; then
  echo "[ERREUR] Domaine introuvable: $DOMAIN_RAW"
  exit 1
fi

if ! PROBLEM_FILE="$(resolve_file "$PROBLEM_RAW")"; then
  echo "[ERREUR] Probleme introuvable: $PROBLEM_RAW"
  exit 1
fi

if [[ $DO_COMPILE -eq 1 ]]; then
  compile
fi

echo "[INFO] Domaine : $DOMAIN_FILE"
echo "[INFO] Probleme: $PROBLEM_FILE"

echo "[INFO] Execution du solveur SAT..."
java -cp "$RUN_CP" -server -Xms"$JAVA_XMS" -Xmx"$JAVA_XMX" "$MAIN_CLASS" "$DOMAIN_FILE" "$PROBLEM_FILE"
