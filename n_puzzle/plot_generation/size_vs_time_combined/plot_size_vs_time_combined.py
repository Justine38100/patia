import argparse
import contextlib
import math
import os
import random
import signal
import sys
import time

import matplotlib.pyplot as plt

SCRIPT_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from n_puzzle.node import Node
from n_puzzle.npuzzle import create_goal, shuffle, is_solution
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


def generate_puzzle(size: int, shuffle_len: int):
    state = create_goal(size)
    for _ in range(shuffle_len):
        state = shuffle(state)
    return state


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


def mean_or_timeout(values, timeout_s):
    if not values:
        return timeout_s
    return sum(values) / len(values)


def main():
    parser = argparse.ArgumentParser(
        description="Plot puzzle size vs resolution time for BFS/DFS/A*."
    )
    parser.add_argument("--min-size", type=int, default=2, help="Minimum size (default: 2)")
    parser.add_argument("--max-size", type=int, default=4, help="Maximum size (default: 4)")
    parser.add_argument("--shuffle", type=int, default=10, help="Shuffle length (default: 10)")
    parser.add_argument("--samples", type=int, default=5, help="Puzzles per size (default: 5)")
    parser.add_argument("--timeout", type=float, default=5.0, help="Timeout per run (s)")
    parser.add_argument("--seed", type=int, default=0, help="Random seed")
    parser.add_argument(
        "--out",
        type=str,
        default=os.path.join(SCRIPT_DIR, "size_vs_time_combined.png"),
        help="Output PNG",
    )
    parser.add_argument("--show", action="store_true", help="Show plot window")
    parser.add_argument("--logy", action="store_true", help="Log scale on Y axis")
    args = parser.parse_args()

    random.seed(args.seed)

    sizes = list(range(args.min_size, args.max_size + 1))
    bfs_means = []
    dfs_means = []
    ast_means = []
    bfs_fail = []
    dfs_fail = []
    ast_fail = []

    for size in sizes:
        bfs_times = []
        dfs_times = []
        ast_times = []
        bfs_failed = False
        dfs_failed = False
        ast_failed = False

        for _ in range(args.samples):
            puzzle = generate_puzzle(size, args.shuffle)

            t, sol, status = run_solver(solve_bfs, puzzle, args.timeout)
            if status == "ok" and sol is not None and is_solution(puzzle, sol):
                bfs_times.append(t)
            else:
                bfs_failed = True

            t, sol, status = run_solver(solve_dfs, puzzle, args.timeout)
            if status == "ok" and sol is not None and is_solution(puzzle, sol):
                dfs_times.append(t)
            else:
                dfs_failed = True

            t, sol, status = run_solver(solve_astar, puzzle, args.timeout)
            if status == "ok" and sol is not None and is_solution(puzzle, sol):
                ast_times.append(t)
            else:
                ast_failed = True

        bfs_means.append(mean_or_timeout(bfs_times, args.timeout))
        dfs_means.append(mean_or_timeout(dfs_times, args.timeout))
        ast_means.append(mean_or_timeout(ast_times, args.timeout))
        bfs_fail.append(bfs_failed)
        dfs_fail.append(dfs_failed)
        ast_fail.append(ast_failed)

    plt.figure(figsize=(10, 5))
    plt.plot(sizes, bfs_means, label="BFS")
    plt.plot(sizes, dfs_means, label="DFS")
    plt.plot(sizes, ast_means, label="A*")

    for i, size in enumerate(sizes):
        if bfs_fail[i]:
            plt.scatter(size, bfs_means[i], marker="x", s=40)
        if dfs_fail[i]:
            plt.scatter(size, dfs_means[i], marker="x", s=40)
        if ast_fail[i]:
            plt.scatter(size, ast_means[i], marker="x", s=40)

    plt.xlabel("Taille du taquin (N)")
    plt.ylabel("Temps moyen de résolution (s)")
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
