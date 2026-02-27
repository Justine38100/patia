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


def plot_one(out_path, title, xs, ys, bad_idx, timeout_s, logy, color, show):
    plt.figure(figsize=(8, 4.5))
    plt.scatter(xs, ys, s=18, color=color, label=title)
    if bad_idx:
        plt.scatter(
            [xs[i] for i in bad_idx],
            [ys[i] for i in bad_idx],
            marker="x",
            s=45,
            color=color,
            label=f"{title} timeout/erreur",
        )
    plt.xlabel("Nombre de coups pour arriver à la solution")
    plt.ylabel("Temps de résolution (s)")
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
        description="Generate three separate plots for BFS/DFS/A* (moves vs time) using the same puzzles."
    )
    parser.add_argument("--size", type=int, required=True, help="Puzzle size (e.g., 3)")
    parser.add_argument("--min-shuffle", type=int, default=1, help="Min shuffle length")
    parser.add_argument("--max-shuffle", type=int, default=20, help="Max shuffle length")
    parser.add_argument("--step", type=int, default=1, help="Shuffle length step")
    parser.add_argument("--samples", type=int, default=3, help="Puzzles per shuffle length")
    parser.add_argument("--timeout", type=float, default=5.0, help="Timeout per run (s)")
    parser.add_argument("--seed", type=int, default=0, help="Random seed")
    parser.add_argument(
        "--out-prefix",
        type=str,
        default=os.path.join(SCRIPT_DIR, "moves"),
        help="Output prefix",
    )
    parser.add_argument("--show", action="store_true", help="Show plot windows")
    parser.add_argument("--logy", action="store_true", help="Log scale on Y axis")
    args = parser.parse_args()

    random.seed(args.seed)

    puzzles = []
    for shuffle_len in range(args.min_shuffle, args.max_shuffle + 1, args.step):
        for _ in range(args.samples):
            puzzles.append((shuffle_len, generate_puzzle(args.size, shuffle_len)))

    bfs_x, bfs_y, bfs_bad = [], [], []
    dfs_x, dfs_y, dfs_bad = [], [], []
    ast_x, ast_y, ast_bad = [], [], []

    for shuffle_len, puzzle in puzzles:
        t, sol, status = run_solver(solve_bfs, puzzle, args.timeout)
        if status == "ok" and sol is not None and is_solution(puzzle, sol):
            bfs_x.append(len(sol))
            bfs_y.append(t)
        else:
            bfs_x.append(shuffle_len)
            bfs_y.append(args.timeout)
            bfs_bad.append(len(bfs_x) - 1)

        t, sol, status = run_solver(solve_dfs, puzzle, args.timeout)
        if status == "ok" and sol is not None and is_solution(puzzle, sol):
            dfs_x.append(len(sol))
            dfs_y.append(t)
        else:
            dfs_x.append(shuffle_len)
            dfs_y.append(args.timeout)
            dfs_bad.append(len(dfs_x) - 1)

        t, sol, status = run_solver(solve_astar, puzzle, args.timeout)
        if status == "ok" and sol is not None and is_solution(puzzle, sol):
            ast_x.append(len(sol))
            ast_y.append(t)
        else:
            ast_x.append(shuffle_len)
            ast_y.append(args.timeout)
            ast_bad.append(len(ast_x) - 1)

    plot_one(
        f"{args.out_prefix}_bfs.png",
        "BFS",
        bfs_x,
        bfs_y,
        bfs_bad,
        args.timeout,
        args.logy,
        "tab:blue",
        args.show,
    )
    plot_one(
        f"{args.out_prefix}_dfs.png",
        "DFS",
        dfs_x,
        dfs_y,
        dfs_bad,
        args.timeout,
        args.logy,
        "tab:orange",
        args.show,
    )
    plot_one(
        f"{args.out_prefix}_astar.png",
        "A*",
        ast_x,
        ast_y,
        ast_bad,
        args.timeout,
        args.logy,
        "tab:green",
        args.show,
    )

    print(
        f"Saved: {args.out_prefix}_bfs.png, {args.out_prefix}_dfs.png, {args.out_prefix}_astar.png"
    )


if __name__ == "__main__":
    main()
