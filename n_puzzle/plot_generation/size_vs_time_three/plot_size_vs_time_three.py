import argparse
import contextlib
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


def evaluate_algo(name, solver, puzzles_by_size, timeout_s):
    sizes = []
    means = []
    failed = []
    for size in sorted(puzzles_by_size.keys()):
        times = []
        any_fail = False
        for puzzle in puzzles_by_size[size]:
            t, sol, status = run_solver(solver, puzzle, timeout_s)
            if status == "ok" and sol is not None and is_solution(puzzle, sol):
                times.append(t)
            else:
                any_fail = True
        sizes.append(size)
        means.append(mean_or_timeout(times, timeout_s))
        failed.append(any_fail)
    return sizes, means, failed


def plot_one(out_path, title, sizes, means, failed, timeout_s, logy, color, show):
    plt.figure(figsize=(8, 4.5))
    plt.plot(sizes, means, color=color, label=title)
    for i, size in enumerate(sizes):
        if failed[i]:
            plt.scatter(size, timeout_s, marker="x", s=50, color=color)
    plt.xlabel("Taille du taquin (N)")
    plt.ylabel("Temps moyen de résolution (s)")
    if logy:
        plt.yscale("log")
    plt.legend()
    plt.tight_layout()
    plt.savefig(out_path, dpi=150)
    if show:
        plt.show()
    plt.close()


def main():
    parser = argparse.ArgumentParser(
        description="Generate three separate plots for BFS, DFS and A* using the same puzzles."
    )
    parser.add_argument("--min-size", type=int, default=2, help="Minimum size (default: 2)")
    parser.add_argument("--max-size", type=int, default=6, help="Maximum size (default: 6)")
    parser.add_argument("--shuffle", type=int, default=10, help="Shuffle length (default: 10)")
    parser.add_argument("--samples", type=int, default=5, help="Puzzles per size (default: 5)")
    parser.add_argument("--timeout", type=float, default=5.0, help="Timeout per run (s)")
    parser.add_argument("--seed", type=int, default=0, help="Random seed")
    parser.add_argument(
        "--out-prefix",
        type=str,
        default=os.path.join(SCRIPT_DIR, "size_time"),
        help="Output prefix",
    )
    parser.add_argument("--show", action="store_true", help="Show plot windows")
    parser.add_argument("--logy", action="store_true", help="Log scale on Y axis")
    args = parser.parse_args()

    random.seed(args.seed)

    puzzles_by_size = {}
    for size in range(args.min_size, args.max_size + 1):
        puzzles = []
        for _ in range(args.samples):
            puzzles.append(generate_puzzle(size, args.shuffle))
        puzzles_by_size[size] = puzzles

    sizes, bfs_means, bfs_failed = evaluate_algo("BFS", solve_bfs, puzzles_by_size, args.timeout)
    _, dfs_means, dfs_failed = evaluate_algo("DFS", solve_dfs, puzzles_by_size, args.timeout)
    _, ast_means, ast_failed = evaluate_algo("A*", solve_astar, puzzles_by_size, args.timeout)

    plot_one(
        f"{args.out_prefix}_bfs.png",
        "BFS",
        sizes,
        bfs_means,
        bfs_failed,
        args.timeout,
        args.logy,
        "tab:blue",
        args.show,
    )
    plot_one(
        f"{args.out_prefix}_dfs.png",
        "DFS",
        sizes,
        dfs_means,
        dfs_failed,
        args.timeout,
        args.logy,
        "tab:orange",
        args.show,
    )
    plot_one(
        f"{args.out_prefix}_astar.png",
        "A*",
        sizes,
        ast_means,
        ast_failed,
        args.timeout,
        args.logy,
        "tab:green",
        args.show,
    )

    print(f"Saved: {args.out_prefix}_bfs.png, {args.out_prefix}_dfs.png, {args.out_prefix}_astar.png")


if __name__ == "__main__":
    main()
