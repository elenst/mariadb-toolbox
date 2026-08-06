#!/usr/bin/env python3
"""Annotate the unmatched trials of an RQG combo results file.

The file holds blocks separated by ####### lines, each starting with "Trial: N".
Any number of adjacent ####### lines counts as a single separator, so single and
double fences (and filtered files that carry a stray leading one) all parse.
Blocks that say "--- NO MATCHES FOUND ---" have no JIRA match yet, so a human
still has to look at trialN.log. This script finds those blocks and writes a
one-few-line description into them, right after the NO MATCHES FOUND line.

Two modes:

  --list            Print a JSON array describing every block: trial number,
                    status, whether it is unmatched, whether it already carries
                    a description, and the trialN.log path next to the file.
  --apply d.json    Read {"93": "description text", ...} and insert each
                    description into the matching block. Blocks not named in the
                    JSON are copied through byte-for-byte.

The script writes no descriptions of its own -- reading the logs is the model's
job, per SKILL.md.
"""

import argparse
import json
import os
import re
import sys

SEP = re.compile(r"^#{3,}\s*$")
TRIAL = re.compile(r"^Trial:\s*(\d+)\s*$")
STATUS = re.compile(r"^Status:\s*(\S+)")
NO_MATCHES = re.compile(r"^-*\s*NO MATCHES FOUND\s*-*\s*$")


class ParseError(Exception):
    """The file does not have the structure this skill knows how to handle."""


def read_lines(path):
    with open(path, encoding="utf-8", errors="surrogateescape") as fh:
        return fh.read().splitlines(keepends=True)


def split_runs(lines):
    """Return [(first_idx, last_idx)] for each run of consecutive separator lines.

    Any number of adjacent ####### lines counts as one separator, so a file whose
    blocks are fenced by single, double or ragged runs of ####### parses the same.
    """
    runs = []
    for i, line in enumerate(lines):
        if not SEP.match(line):
            continue
        if runs and runs[-1][1] == i - 1:
            runs[-1][1] = i
        else:
            runs.append([i, i])
    return [(a, b) for a, b in runs]


def split_blocks(lines):
    """Return ([(open_idx, close_idx)], runs).

    A block is whatever sits between two separator runs. open_idx is the last
    separator line of the run before it, close_idx the first separator line of
    the run after it.
    """
    runs = split_runs(lines)
    if not runs:
        raise ParseError("no ####### separator lines found -- is this an RQG results file?")
    if len(runs) < 2:
        raise ParseError(
            "only one ####### separator run; there is no block between two separators"
        )
    pairs = [(runs[i][1], runs[i + 1][0]) for i in range(len(runs) - 1)]
    return pairs, runs


def describe(lines, open_idx, close_idx, base_dir):
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

    status_line = next((STATUS.match(line) for line in text if STATUS.match(line)), None)
    nm_at = next((i for i, line in enumerate(text) if NO_MATCHES.match(line)), None)

    # Anything non-blank between the NO MATCHES FOUND line and the closing
    # separator is a description somebody (probably a previous run) already put
    # there.
    existing = []
    if nm_at is not None:
        existing = [line for line in text[nm_at + 1 :] if line.strip()]

    log = os.path.join(base_dir, f"trial{trial}.log")
    return {
        "trial": trial,
        "first_line": open_idx + 1,  # 1-indexed, the opening separator
        "last_line": close_idx + 1,
        "status": status_line.group(1) if status_line else None,
        "no_matches_found": nm_at is not None,
        "described": bool(existing),
        "existing_description": existing,
        "log": log,
        "log_exists": os.path.isfile(log),
        "log_gz_exists": os.path.isfile(log + ".gz"),
    }


def annotate(lines, open_idx, close_idx, description):
    """Return the block's body with `description` placed after NO MATCHES FOUND.

    The body is what sits between the separator runs -- the separators themselves
    are copied through by the caller.
    """
    body = lines[open_idx + 1 : close_idx]
    nm_at = next(
        (i for i, line in enumerate(body) if NO_MATCHES.match(line.rstrip("\n"))), None
    )
    if nm_at is None:
        raise ParseError(f"block at line {open_idx + 1} has no NO MATCHES FOUND line")

    head = body[: nm_at + 1]
    existing = [line for line in body[nm_at + 1 :] if line.strip()]
    if existing:
        raise ParseError(
            f"block at line {open_idx + 1} already carries a description "
            f"({existing[0].strip()!r}...); pass --replace to overwrite it"
        )

    desc = [line + "\n" for line in description.strip("\n").split("\n")]
    return head + ["\n"] + desc + ["\n"]


def annotate_replacing(lines, open_idx, close_idx, description):
    """Same, but drop whatever description was already there."""
    body = lines[open_idx + 1 : close_idx]
    nm_at = next(
        (i for i, line in enumerate(body) if NO_MATCHES.match(line.rstrip("\n"))), None
    )
    if nm_at is None:
        raise ParseError(f"block at line {open_idx + 1} has no NO MATCHES FOUND line")
    head = body[: nm_at + 1]
    desc = [line + "\n" for line in description.strip("\n").split("\n")]
    return head + ["\n"] + desc + ["\n"]


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("path")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true", help="describe every block as JSON")
    mode.add_argument("--apply", metavar="JSON", help='file holding {"93": "text", ...}')
    ap.add_argument(
        "--replace",
        action="store_true",
        help="overwrite a description that is already present instead of erroring",
    )
    ap.add_argument("--output", help="write --apply result here (default: in place)")
    args = ap.parse_args()

    lines = read_lines(args.path)
    base_dir = os.path.dirname(os.path.abspath(args.path))
    try:
        pairs, runs = split_blocks(lines)
        blocks = [describe(lines, a, b, base_dir) for a, b in pairs]
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

    with open(args.apply, encoding="utf-8") as fh:
        descriptions = {int(k): v for k, v in json.load(fh).items()}

    unknown = sorted(set(descriptions) - set(trials))
    if unknown:
        print(f"ERROR: no such trials in {args.path}: {unknown}", file=sys.stderr)
        return 2
    unmatched = {b["trial"] for b in blocks if b["no_matches_found"]}
    misplaced = sorted(set(descriptions) - unmatched)
    if misplaced:
        print(
            f"ERROR: trials {misplaced} have no NO MATCHES FOUND line -- "
            f"they are matched blocks and must not be annotated",
            file=sys.stderr,
        )
        return 2

    # Everything up to and including the first separator run, then block body /
    # separator run in turn, then whatever trails the last run: separator runs are
    # copied through verbatim, however long they are.
    out = list(lines[: runs[0][1] + 1])
    written = []
    try:
        for i, ((a, b), block) in enumerate(zip(pairs, blocks)):
            if block["trial"] in descriptions:
                fn = annotate_replacing if args.replace else annotate
                out.extend(fn(lines, a, b, descriptions[block["trial"]]))
                written.append(block["trial"])
            else:
                out.extend(lines[a + 1 : b])
            out.extend(lines[runs[i + 1][0] : runs[i + 1][1] + 1])
    except ParseError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    out.extend(lines[runs[-1][1] + 1 :])

    dest = args.output or args.path
    with open(dest, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.writelines(out)
    print(f"described {len(written)}/{len(unmatched)} unmatched trials -> {dest}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
