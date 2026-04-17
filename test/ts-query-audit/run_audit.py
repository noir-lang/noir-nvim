#!/usr/bin/env python3
"""Run queries/noir/highlights.scm against every fixture and dump the
effective capture per token.

Emits per-fixture reports that are diffable across iterations.

Effective-capture rule (matches nvim-treesitter default):
    when several patterns match the same byte range, the pattern with
    the HIGHEST index in highlights.scm wins. The query CLI prefixes
    each match with `pattern: N`; we keep the match whose N is largest
    per (start, end) pair. File-order is not reliable; tree-sitter
    emits matches in tree-traversal order.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRAMMAR = Path.home() / "source" / "tree_sitter_noir"
QUERY = REPO / "queries" / "noir" / "highlights.scm"
FIXTURES_DIR = REPO / "test" / "fixtures"
OUT_DIR = REPO / "test" / "ts-query-audit"

FIXTURES = [
    FIXTURES_DIR / "plain/src/lib.nr",
    FIXTURES_DIR / "plain/src/math.nr",
    FIXTURES_DIR / "plain/src/shapes.nr",
    FIXTURES_DIR / "aztec-token/src/main.nr",
    FIXTURES_DIR / "aztec-storage/src/main.nr",
    FIXTURES_DIR / "aztec-storage/src/profile_note.nr",
    FIXTURES_DIR / "aztec-storage/src/settings.nr",
    FIXTURES_DIR / "aztec-authwit/src/main.nr",
    FIXTURES_DIR / "malformed/bad_attribute.nr",
    FIXTURES_DIR / "malformed/half_struct.nr",
    FIXTURES_DIR / "malformed/partial_decls.nr",
    FIXTURES_DIR / "malformed/unclosed_brace.nr",
]

PATTERN_RE = re.compile(r"^\s*pattern:\s+(?P<idx>\d+)\s*$")
CAPTURE_RE = re.compile(
    r"capture:\s+\d+\s+-\s+(?P<name>\S+),\s+"
    r"start:\s+\((?P<sr>\d+),\s*(?P<sc>\d+)\),\s+"
    r"end:\s+\((?P<er>\d+),\s*(?P<ec>\d+)\),\s+"
    r"text:\s+`(?P<text>.*)`\s*$"
)


def run_query(fixture: Path) -> str:
    result = subprocess.run(
        ["tree-sitter", "query", str(QUERY), str(fixture)],
        cwd=str(GRAMMAR),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 and not result.stdout:
        sys.stderr.write(
            f"tree-sitter query failed for {fixture}:\n{result.stderr}\n"
        )
        return ""
    return result.stdout


def extract_effective(raw: str) -> list[tuple[tuple[int, int, int, int], str, str, int]]:
    """Return a list of (range, capture, text, pattern_idx) in source order.

    For each byte range we keep the match with the HIGHEST pattern index
    (i.e. the rule declared latest in the query file). Ranges are
    (start_row, start_col, end_row, end_col). Source order is the first
    byte position where the winning capture was seen.
    """
    best: dict[tuple[int, int, int, int], tuple[int, str, str]] = {}
    first_seen: dict[tuple[int, int, int, int], int] = {}
    seq = 0
    current_pattern = -1
    for line in raw.splitlines():
        pm = PATTERN_RE.match(line)
        if pm:
            current_pattern = int(pm["idx"])
            continue
        m = CAPTURE_RE.search(line)
        if not m:
            continue
        key = (
            int(m["sr"]),
            int(m["sc"]),
            int(m["er"]),
            int(m["ec"]),
        )
        prev = best.get(key)
        if prev is None or current_pattern > prev[0]:
            best[key] = (current_pattern, m["name"], m["text"])
        if key not in first_seen:
            first_seen[key] = seq
            seq += 1
    ordered = sorted(best.keys(), key=lambda k: (k[0], k[1], k[2], k[3]))
    return [(k, best[k][1], best[k][2], best[k][0]) for k in ordered]


def format_report(fixture: Path, entries) -> str:
    header = f"# {fixture.relative_to(REPO)}\n"
    header += f"#   captures: {len(entries)}\n"
    header += "#   columns: row:col-row:col  capture  (pattern)  text\n"
    body_lines = []
    for (sr, sc, er, ec), name, text, pidx in entries:
        display_text = text if text else "<empty>"
        body_lines.append(
            f"{sr:>3}:{sc:<3}-{er:>3}:{ec:<3}  {name:<28} (p{pidx:>2})  {display_text}"
        )
    return header + "\n".join(body_lines) + "\n"


def main() -> int:
    if not QUERY.is_file():
        sys.stderr.write(f"missing query file: {QUERY}\n")
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for fx in FIXTURES:
        if not fx.is_file():
            sys.stderr.write(f"skip missing fixture: {fx}\n")
            continue
        raw = run_query(fx)
        entries = extract_effective(raw)
        rel = fx.relative_to(FIXTURES_DIR)
        out = OUT_DIR / (str(rel).replace("/", "__") + ".captures")
        out.write_text(format_report(fx, entries))
        print(f"wrote {out.relative_to(REPO)}  ({len(entries)} captures)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
