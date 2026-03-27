#!/usr/bin/env python3

import argparse
import json
import os
import re
import sys
from collections import deque

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
JSON_DIR = os.path.join(REPO_ROOT, "sokoban-master", "config")
PDDL_DIR = os.path.join(REPO_ROOT, "pddl", "sokoban", "pb_json")


class ConversionError(Exception):
    pass


def _strip_pddl_comments(text: str) -> str:
    lines = []
    for line in text.splitlines():
        if ";" in line:
            line = line.split(";", 1)[0]
        lines.append(line)
    return "\n".join(lines)


def _extract_block(text: str, keyword: str) -> str:
    start = text.find(keyword)
    if start < 0:
        raise ConversionError(f"Block not found: {keyword}")

    depth = 0
    in_block = False
    end = start
    for i in range(start, len(text)):
        c = text[i]
        if c == "(":
            depth += 1
            in_block = True
        elif c == ")":
            depth -= 1
            if in_block and depth == 0:
                end = i + 1
                break

    if end <= start:
        raise ConversionError(f"Malformed block for keyword: {keyword}")
    return text[start:end]


def _parse_objects(objects_block: str):
    payload = objects_block
    payload = payload.replace("(:objects", "")
    payload = payload.replace("(", " ").replace(")", " ")
    tokens = payload.split()

    cells = []
    boxes = []
    pending = []
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok == "-":
            if i + 1 >= len(tokens):
                raise ConversionError("Invalid :objects section, missing type after '-'.")
            typ = tokens[i + 1]
            if typ == "cell":
                cells.extend(pending)
            elif typ == "box":
                boxes.extend(pending)
            pending = []
            i += 2
            continue
        pending.append(tok)
        i += 1

    if not cells:
        raise ConversionError("No cell objects found in :objects.")
    return sorted(set(cells), key=cell_sort_key), sorted(set(boxes), key=box_sort_key)


def _parse_init_atoms(init_block: str):
    atoms = []
    for m in re.finditer(r"\(([a-zA-Z0-9_-]+)([^()]*)\)", init_block):
        pred = m.group(1).lower()
        if pred.startswith(":"):
            continue
        args = [a for a in m.group(2).split() if a]
        atoms.append((pred, args))
    return atoms


def cell_sort_key(name: str):
    m = re.fullmatch(r"c(\d+)", name.lower())
    if m:
        return (0, int(m.group(1)))
    return (1, name.lower())


def box_sort_key(name: str):
    m = re.fullmatch(r"b(\d+)", name.lower())
    if m:
        return (0, int(m.group(1)))
    return (1, name.lower())


def _safe_basename(path: str) -> str:
    base = os.path.basename(path)
    stem, _ = os.path.splitext(base)
    if not stem:
        raise ConversionError(f"Invalid filename: {path}")
    return stem


def _coords_to_cell_name(x: int, y: int, width: int) -> str:
    return f"c{y * width + x + 1}"


def _cell_name_to_index(name: str) -> int:
    m = re.fullmatch(r"c(\d+)", name.lower())
    if not m:
        raise ConversionError(f"Cell name is not in c<number> format: {name}")
    return int(m.group(1))


def json_to_pddl(json_path: str) -> str:
    if not os.path.isfile(json_path):
        raise ConversionError(f"JSON file not found: {json_path}")

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    test_in = data.get("testIn")
    if not isinstance(test_in, str) or not test_in:
        raise ConversionError("JSON must contain non-empty string field 'testIn'.")

    rows = test_in.split("\n")
    height = len(rows)
    width = max(len(r) for r in rows)
    grid = [list(r.ljust(width)) for r in rows]

    player_positions = []
    goals = set()
    boxes = []

    for ry in range(height):
        for rx in range(width):
            ch = grid[ry][rx]
            if ch in "@+":
                player_positions.append((rx, ry))
            if ch in ".*+":
                goals.add((rx, ry))
            if ch in "$*":
                boxes.append((rx, ry))

    if len(player_positions) != 1:
        raise ConversionError(f"Expected exactly one player (@ or +), found {len(player_positions)}.")

    if len(boxes) == 0:
        raise ConversionError("Expected at least one box ($ or *).")

    if len(goals) != len(boxes):
        raise ConversionError(
            f"Number of goals ({len(goals)}) must match number of boxes ({len(boxes)})."
        )

    player = player_positions[0]

    def walkable(x, y):
        if not (0 <= x < width and 0 <= y < height):
            return False
        return grid[y][x] != "#"

    # Keep only cells connected to player (same behavior as java outside-detection).
    q = deque([player])
    visited = {player}
    while q:
        x, y = q.popleft()
        for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
            nx, ny = x + dx, y + dy
            if (nx, ny) not in visited and walkable(nx, ny):
                visited.add((nx, ny))
                q.append((nx, ny))

    for bx, by in boxes:
        if (bx, by) not in visited:
            raise ConversionError("A box is not connected to the player area.")
    for gx, gy in goals:
        if (gx, gy) not in visited:
            raise ConversionError("A goal is not connected to the player area.")

    # Convert screen coords (top-left origin) to pddl coords (bottom-left origin)
    playable = []
    for (x, y_top) in visited:
        y = (height - 1) - y_top
        playable.append((x, y))

    playable_set = set(playable)
    player_xy = (player[0], (height - 1) - player[1])
    boxes_xy = [(x, (height - 1) - y) for x, y in boxes]
    goals_xy = [(x, (height - 1) - y) for x, y in goals]

    cell_names = sorted(
        [_coords_to_cell_name(x, y, width) for (x, y) in playable_set],
        key=cell_sort_key,
    )

    box_cells = sorted(
        [_coords_to_cell_name(x, y, width) for (x, y) in boxes_xy],
        key=cell_sort_key,
    )
    goal_cells = sorted(
        [_coords_to_cell_name(x, y, width) for (x, y) in goals_xy],
        key=cell_sort_key,
    )

    player_cell = _coords_to_cell_name(player_xy[0], player_xy[1], width)

    boxes_names = [f"b{i + 1}" for i in range(len(box_cells))]

    clear_cells = sorted(
        set(cell_names) - {player_cell} - set(box_cells),
        key=cell_sort_key,
    )

    stem = _safe_basename(json_path)
    problem_name = re.sub(r"[^a-zA-Z0-9_-]", "_", stem)

    lines = []
    lines.append(f"; Auto-generated from JSON: {os.path.basename(json_path)}")
    lines.append(f"; Grid width={width}, height={height}")
    lines.append("")
    lines.append(f"(define (problem {problem_name})")
    lines.append("  (:domain sokoban)")
    lines.append("")
    lines.append("  (:objects")
    lines.append("    " + " ".join(cell_names) + " - cell")
    lines.append("    " + " ".join(boxes_names) + " - box")
    lines.append("  )")
    lines.append("")
    lines.append("  (:init")

    # Directional adjacencies
    for c in cell_names:
        idx = _cell_name_to_index(c)
        x = (idx - 1) % width
        y = (idx - 1) // width
        n = (x, y + 1)
        s = (x, y - 1)
        e = (x + 1, y)
        w = (x - 1, y)

        if n in playable_set:
            lines.append(f"    (north {c} {_coords_to_cell_name(n[0], n[1], width)})")
        if s in playable_set:
            lines.append(f"    (south {c} {_coords_to_cell_name(s[0], s[1], width)})")
        if e in playable_set:
            lines.append(f"    (east {c} {_coords_to_cell_name(e[0], e[1], width)})")
        if w in playable_set:
            lines.append(f"    (west {c} {_coords_to_cell_name(w[0], w[1], width)})")

    lines.append("")
    lines.append(f"    (at-player {player_cell})")

    for b, c in zip(boxes_names, box_cells):
        lines.append(f"    (at-box {b} {c})")

    for g in goal_cells:
        lines.append(f"    (goal {g})")

    for c in clear_cells:
        lines.append(f"    (clear {c})")

    lines.append("  )")
    lines.append("")
    lines.append("  (:goal (and")
    for b, g in zip(boxes_names, goal_cells):
        lines.append(f"    (at-box {b} {g})")
    lines.append("  ))")
    lines.append(")")

    output = os.path.join(PDDL_DIR, f"{stem}.pddl")
    os.makedirs(PDDL_DIR, exist_ok=True)
    with open(output, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    return output


def pddl_to_json(pddl_path: str) -> str:
    if not os.path.isfile(pddl_path):
        raise ConversionError(f"PDDL file not found: {pddl_path}")

    with open(pddl_path, "r", encoding="utf-8") as f:
        raw = f.read()

    text = _strip_pddl_comments(raw)
    text_l = text.lower()

    objects_block = _extract_block(text_l, "(:objects")
    init_block = _extract_block(text_l, "(:init")

    cells, boxes = _parse_objects(objects_block)
    atoms = _parse_init_atoms(init_block)

    deltas = {
        "north": (0, 1),
        "south": (0, -1),
        "east": (1, 0),
        "west": (-1, 0),
    }

    coords = {}

    # Build an undirected constraint graph from directional predicates.
    rels = []
    player_cell = None
    box_pos = {}
    goal_cells = set()

    for pred, args in atoms:
        if pred in deltas:
            if len(args) == 2:
                rels.append((pred, args[0], args[1]))
        elif pred == "at-player" and len(args) == 1:
            player_cell = args[0]
        elif pred == "at-box" and len(args) == 2:
            box_pos[args[0]] = args[1]
        elif pred == "goal" and len(args) == 1:
            goal_cells.add(args[0])

    if player_cell is None:
        raise ConversionError("No (at-player ...) found in :init.")

    for c in cells:
        coords.setdefault(c, None)

    # Multi-component assignment (rare, but safe)
    component_anchor = 0
    for start in cells:
        if coords[start] is not None:
            continue
        coords[start] = (component_anchor, 0)
        component_anchor += 1000
        q = deque([start])
        while q:
            cur = q.popleft()
            cx, cy = coords[cur]
            for pred, a, b in rels:
                dx, dy = deltas[pred]
                if a == cur:
                    expected = (cx + dx, cy + dy)
                    if coords.get(b) is None:
                        coords[b] = expected
                        q.append(b)
                    elif coords[b] != expected:
                        raise ConversionError("Inconsistent directional constraints in PDDL.")
                if b == cur:
                    expected = (cx - dx, cy - dy)
                    if coords.get(a) is None:
                        coords[a] = expected
                        q.append(a)
                    elif coords[a] != expected:
                        raise ConversionError("Inconsistent directional constraints in PDDL.")

    assigned = {c: xy for c, xy in coords.items() if xy is not None}
    if len(assigned) != len(cells):
        raise ConversionError("Some cells could not be assigned coordinates.")

    xs = [xy[0] for xy in assigned.values()]
    ys = [xy[1] for xy in assigned.values()]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)

    width = (max_x - min_x) + 1
    height = (max_y - min_y) + 1

    # Add a border of walls around the reconstructed playable area.
    grid_width = width + 2
    grid_height = height + 2
    map_grid = [["#" for _ in range(grid_width)] for _ in range(grid_height)]

    for c, (x, y) in assigned.items():
        gx = (x - min_x) + 1
        gy = (max_y - y) + 1  # convert to top-origin with border offset
        map_grid[gy][gx] = " "

    # Goals
    for g in goal_cells:
        if g not in assigned:
            raise ConversionError(f"Goal cell not declared in objects: {g}")
        x, y = assigned[g]
        gx = (x - min_x) + 1
        gy = (max_y - y) + 1
        map_grid[gy][gx] = "."

    # Boxes
    for b in sorted(box_pos.keys(), key=box_sort_key):
        c = box_pos[b]
        if c not in assigned:
            raise ConversionError(f"Box cell not declared in objects: {c}")
        x, y = assigned[c]
        gx = (x - min_x) + 1
        gy = (max_y - y) + 1
        map_grid[gy][gx] = "*" if map_grid[gy][gx] == "." else "$"

    # Player
    if player_cell not in assigned:
        raise ConversionError(f"Player cell not declared in objects: {player_cell}")
    px, py = assigned[player_cell]
    gpx = (px - min_x) + 1
    gpy = (max_y - py) + 1
    map_grid[gpy][gpx] = "+" if map_grid[gpy][gpx] == "." else "@"

    lines = ["".join(r) for r in map_grid]
    test_in = "\n".join(lines)

    stem = _safe_basename(pddl_path)
    payload = {
        "title": {"2": stem},
        "testIn": test_in,
        "isTest": "true",
        "isValidator": "true",
    }

    output = os.path.join(JSON_DIR, f"{stem}.json")
    os.makedirs(JSON_DIR, exist_ok=True)
    with open(output, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
        f.write("\n")

    return output


def convert_auto(input_path: str) -> str:
    ext = os.path.splitext(input_path)[1].lower()
    if ext == ".json":
        return json_to_pddl(input_path)
    if ext == ".pddl":
        return pddl_to_json(input_path)
    raise ConversionError("Input file must end with .json or .pddl")


def main():
    parser = argparse.ArgumentParser(
        description="Convert Sokoban level files between JSON and PDDL with fixed output directories."
    )
    parser.add_argument("input", help="Input file (.json or .pddl)")
    args = parser.parse_args()

    try:
        output = convert_auto(os.path.abspath(args.input))
    except ConversionError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as e:
        print(f"Error: invalid JSON: {e}", file=sys.stderr)
        return 1

    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
