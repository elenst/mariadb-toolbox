#!/usr/bin/env python3
"""Split / rejoin RQG combo result files on their ####### block separators.

Two modes:

  --list            Print a JSON array describing every block: trial number,
                    line range, and the facts needed to decide keep vs. remove.
  --keep 3,7,12     Write the file back containing only those trial numbers,
                    byte-for-byte identical for the blocks that survive.

The script makes no keep/remove decisions of its own -- that judgement lives
in SKILL.md, because it needs JIRA and MariaDB release knowledge.
"""

import argparse
import json
import re
import sys

SEP = re.compile(r"^#{3,}\s*$")
TRIAL = re.compile(r"^Trial:\s*(\d+)\s*$")
STATUS_OK = re.compile(r"exit status STATUS_OK")
STATUS = re.compile(r"^Status:\s*(\S+)")
NO_MATCHES = re.compile(r"NO MATCHES FOUND")
ATTENTION = re.compile(r"ATTENTION! FOUND CLOSED MDEV")
MATCH_HDR = re.compile(r"^---\s*(STRONG|WEAK) matches")
ENTRY = re.compile(r"^((?:MDEV|MENT|TODO)-\d+):\s*(.*)$")
RESOLUTION = re.compile(r"^RESOLUTION:\s*(.+?)\s*$")
FIX_VERSIONS = re.compile(r"^Fix versions:\s*(.*?)\s*(?:\(\d{4}-\d{2}-\d{2}\))?\s*$")
ATTN_TICKET = re.compile(r"^\s*((?:MDEV|MENT)-\d+)")
RULE = re.compile(r"^-{3,}\s*$")


class ParseError(Exception):
    """The file does not have the structure this skill knows how to handle."""


def read_lines(path):
    with open(path, encoding="utf-8", errors="surrogateescape") as fh:
        return fh.read().splitlines(keepends=True)


def split_blocks(lines):
    """Return (preamble, [(open_idx, close_idx)], trailer_start).

    Blocks are delimited by a pair of separator lines: an opening ####### and a
    closing #######. They are not shared between adjacent blocks.
    """
    seps = [i for i, line in enumerate(lines) if SEP.match(line)]
    if not seps:
        raise ParseError("no ####### separator lines found -- is this an RQG results file?")
    if len(seps) % 2:
        raise ParseError(
            f"odd number of separator lines ({len(seps)}); the last block looks unterminated"
        )
    return list(zip(seps[0::2], seps[1::2])), seps[0], seps[-1]


def parse_entries(body_lines):
    """Pull the MDEV / MENT / TODO records out of a match section."""
    entries = []
    current = None
    for line in body_lines:
        hit = ENTRY.match(line)
        if hit:
            current = {
                "id": hit.group(1),
                "kind": hit.group(1).split("-")[0],
                "note": hit.group(2).strip(),
                "resolution": None,
                "fix_versions": [],
            }
            entries.append(current)
            continue
        if current is None:
            continue
        res = RESOLUTION.match(line)
        if res:
            current["resolution"] = res.group(1)
            continue
        fix = FIX_VERSIONS.match(line)
        if fix:
            current["fix_versions"] = fix.group(1).split()
    return entries


def describe(lines, open_idx, close_idx):
    body = lines[open_idx + 1 : close_idx]
    text = [line.rstrip("\n") for line in body]

    non_empty = [line for line in text if line.strip()]
    if not non_empty:
        raise ParseError(f"empty block at line {open_idx + 1}")
    hit = TRIAL.match(non_empty[0])
    if not hit:
        raise ParseError(
            f"block at line {open_idx + 1} does not start with 'Trial: N' "
            f"(found {non_empty[0]!r})"
        )
    trial = int(hit.group(1))

    # Split the body into the match section and the ATTENTION section.
    attn_at = next((i for i, line in enumerate(text) if ATTENTION.search(line)), None)
    match_lines = text[1:attn_at] if attn_at is not None else text[1:]
    attn_lines = text[attn_at + 1 :] if attn_at is not None else []

    attention_tickets = []
    for line in attn_lines:
        if RULE.match(line):
            continue
        found = ATTN_TICKET.match(line)
        if found:
            attention_tickets.append(found.group(1))

    status_line = next((STATUS.match(line) for line in text if STATUS.match(line)), None)
    entries = parse_entries(match_lines)

    return {
        "trial": trial,
        "first_line": open_idx + 1,  # 1-indexed, the opening separator
        "last_line": close_idx + 1,
        "status_ok": any(STATUS_OK.search(line) for line in text),
        "status": status_line.group(1) if status_line else None,
        "match_kinds": sorted({m.group(1) for m in map(MATCH_HDR.match, text) if m}),
        "no_matches_found": any(NO_MATCHES.search(line) for line in text),
        "has_attention": attn_at is not None,
        "attention_tickets": attention_tickets,
        "entries": entries,
        "ment_ids": [e["id"] for e in entries if e["kind"] == "MENT"],
        "mdev_ids": [e["id"] for e in entries if e["kind"] == "MDEV"],
        "todo_ids": [e["id"] for e in entries if e["kind"] == "TODO"],
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("path")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true", help="describe every block as JSON")
    mode.add_argument("--keep", help="comma-separated trial numbers to keep")
    ap.add_argument("--output", help="write --keep result here (default: in place)")
    args = ap.parse_args()

    lines = read_lines(args.path)
    try:
        pairs, first, last = split_blocks(lines)
        blocks = [describe(lines, a, b) for a, b in pairs]
    except ParseError as exc:
        print(f"UNRECOGNISED STRUCTURE: {exc}", file=sys.stderr)
        return 2

    trials = [b["trial"] for b in blocks]
    dupes = sorted({t for t in trials if trials.count(t) > 1})
    if dupes:
        print(f"UNRECOGNISED STRUCTURE: duplicate trial numbers {dupes}", file=sys.stderr)
        return 2

    if args.list:
        json.dump(blocks, sys.stdout, indent=1)
        sys.stdout.write("\n")
        return 0

    wanted = {int(x) for x in args.keep.split(",") if x.strip()}
    unknown = sorted(wanted - set(trials))
    if unknown:
        print(f"ERROR: no such trials in {args.path}: {unknown}", file=sys.stderr)
        return 2

    out = list(lines[:first])
    for (a, b), block in zip(pairs, blocks):
        if block["trial"] in wanted:
            out.extend(lines[a : b + 1])
    out.extend(lines[last + 1 :])

    dest = args.output or args.path
    with open(dest, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.writelines(out)
    print(f"kept {len(wanted)}/{len(blocks)} trials -> {dest}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
