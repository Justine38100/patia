import argparse
import contextlib
import glob
import math
import os
import signal
import sys
import time

import matplotlib.pyplot as plt

SCRIPT_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from n_puzzle.node import Node
from n_puzzle.npuzzle import load_puzzle, is_solution
from n_puzzle.solve_npuzzle import solve_bfs, solve_dfs, solve_astar


@contextlib.contextmanager
def time_limit(seconds: float):
    def handler(signum, frame):
        raise TimeoutError("timeout")

    old_handler = signal.signal(signal.SIGALRM, handler)
    signal.setitimer(signal.ITIMER_REAL, seconds)
    try:
        yield
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, old_handler)


def run_solver(solver, puzzle, timeout_s: float):
    root = Node(state=puzzle, move=None)
    start = time.perf_counter()
    try:
        with time_limit(timeout_s):
            sol = solver([root])
        duration = time.perf_counter() - start
    except TimeoutError:
        return timeout_s, None, "timeout"
    except RecursionError:
        duration = time.perf_counter() - start
        return duration, None, "recursion"
    except Exception as exc:
        duration = time.perf_counter() - start
        return duration, None, f"error:{exc.__class__.__name__}"
    return duration, sol, "ok"


def main():
    parser = argparse.ArgumentParser(
        description="Benchmark BFS/DFS/A* on a set of n-puzzle instances."
    )
    parser.add_argument(
        "pattern",
        nargs="?",
        default="puzzles/*.txt",
        help="Glob pattern for puzzle files (default: puzzles/*.txt)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=5.0,
        help="Timeout per algorithm and puzzle in seconds (default: 5.0)",
    )
    parser.add_argument(
        "--out",
        type=str,
        default=os.path.join(SCRIPT_DIR, "sorted_puzzles_time.png"),
        help="Output PNG file",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Display the plot in a window",
    )
    parser.add_argument(
        "--sort",
        choices=["bfs_len", "bfs_time"],
        default="bfs_len",
        help="Sort puzzles by BFS solution length or BFS time (default: bfs_len)",
    )
    parser.add_argument(
        "--logy",
        action="store_true",
        help="Use log scale on Y axis",
    )
    args = parser.parse_args()

    files = sorted(glob.glob(args.pattern))
    if not files:
        print(f"No puzzle files matched: {args.pattern}")
        return

    rows = []
    for path in files:
        puzzle = load_puzzle(path)

        bfs_time, bfs_sol, bfs_status = run_solver(solve_bfs, puzzle, args.timeout)
        bfs_ok = bfs_sol is not None and is_solution(puzzle, bfs_sol)
        bfs_len = len(bfs_sol) if bfs_ok else math.inf

        dfs_time, dfs_sol, dfs_status = run_solver(solve_dfs, puzzle, args.timeout)
        dfs_ok = dfs_sol is not None and is_solution(puzzle, dfs_sol)
        dfs_time = dfs_time if dfs_ok else math.inf

        ast_time, ast_sol, ast_status = run_solver(solve_astar, puzzle, args.timeout)
        ast_ok = ast_sol is not None and is_solution(puzzle, ast_sol)
        ast_time = ast_time if ast_ok else math.inf

        rows.append(
            {
                "path": path,
                "bfs_len": bfs_len,
                "bfs_time": bfs_time if bfs_ok else math.inf,
                "dfs_time": dfs_time,
                "ast_time": ast_time,
                "bfs_status": bfs_status,
                "dfs_status": dfs_status,
                "ast_status": ast_status,
            }
        )

    rows.sort(key=lambda r: r[args.sort])

    xs = list(range(len(rows)))

    def series_with_timeouts(time_key, status_key):
        values = []
        bad_idx = []
        for i, r in enumerate(rows):
            status = r[status_key]
            v = r[time_key]
            if status != "ok" or math.isinf(v):
                v = args.timeout
                bad_idx.append(i)
            if args.logy:
                v = max(v, 1e-6)
            values.append(v)
        return values, bad_idx

    bfs, bfs_bad = series_with_timeouts("bfs_time", "bfs_status")
    dfs, dfs_bad = series_with_timeouts("dfs_time", "dfs_status")
    ast, ast_bad = series_with_timeouts("ast_time", "ast_status")

    plt.figure(figsize=(10, 5))
    plt.plot(xs, bfs, label="BFS")
    plt.plot(xs, dfs, label="DFS")
    plt.plot(xs, ast, label="A*")
    if bfs_bad:
        plt.scatter(
            [xs[i] for i in bfs_bad],
            [bfs[i] for i in bfs_bad],
            marker="x",
            s=30,
            label="BFS timeout/erreur",
        )
    if dfs_bad:
        plt.scatter(
            [xs[i] for i in dfs_bad],
            [dfs[i] for i in dfs_bad],
            marker="x",
            s=30,
            label="DFS timeout/erreur",
        )
    if ast_bad:
        plt.scatter(
            [xs[i] for i in ast_bad],
            [ast[i] for i in ast_bad],
            marker="x",
            s=30,
            label="A* timeout/erreur",
        )
    sort_label = "longueur BFS" if args.sort == "bfs_len" else "temps BFS"
    plt.xlabel(f"Puzzles triés (facile → difficile selon {sort_label})")
    plt.ylabel("Temps de résolution (s)")
    if args.logy:
        plt.yscale("log")
    plt.legend()
    plt.tight_layout()
    plt.savefig(args.out, dpi=150)

    if args.show:
        plt.show()

    print(f"Saved plot to {args.out}")


if __name__ == "__main__":
    main()
