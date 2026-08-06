---
name: rqg-trial-filter
description: Filter an RQG combo results file down to the trials that actually need attention. The file holds blocks separated by ####### lines, each starting with "Trial: N", and each either passing (STATUS_OK), unmatched (NO MATCHES FOUND), or matched against JIRA tickets (MDEV/MENT/TODO), optionally with an "ATTENTION! FOUND CLOSED MDEV" section. Keeps unmatched trials, MENT matches, and closed MDEVs whose fix has already shipped; drops passing trials, known-unresolved bugs and TODO-only matches. Use when asked to filter, trim, triage or clean up RQG results, combo results, or a results-*.txt trial file.
---

# Filter RQG combo results

Rewrite an RQG results file in place, keeping only the trial blocks worth a human
look. A `<filename>.bak` backup is made first.

## 1. Get the file

The path comes in as the skill argument. If no argument was given, ask the user for
the path — do not guess, and do not scan the directory for candidates.

Read the file. Then run:

```bash
python3 ~/.claude/skills/rqg-trial-filter/scripts/rqg_blocks.py <file> --list
```

This prints one JSON record per block with everything the rules below need:
`trial`, `status_ok`, `status`, `no_matches_found`, `has_attention`,
`attention_tickets`, `entries` (each with `id`, `kind`, `resolution`,
`fix_versions`), plus `mdev_ids` / `ment_ids` / `todo_ids`.

If the script exits with `UNRECOGNISED STRUCTURE`, stop and show the user the
message — the file is not in the expected shape and guessing would corrupt it.

## 2. Back up

```bash
cp <file> <file>.bak
```

`-n` so an existing backup is never clobbered. If `<file>.bak` already exists, tell
the user and ask whether to overwrite it, keep it, or write `<file>.bak2` — do not
decide alone; the existing backup may be the only copy of an earlier state.

## 3. Find the current MariaDB releases

Needed only if some block has `has_attention: true`. Skip the lookup otherwise.

Determine, for every branch named in the relevant `fix_versions`, the newest
**GA-released** version of that branch. Try in order:

```bash
curl -s https://endoflife.date/api/mariadb.json
```

which gives `cycle` + `latest` per branch. Cross-check anything decisive against
<https://mariadb.org/mariadb/all-releases/> (WebFetch). If neither source is
reachable, ask the user which versions are current rather than guessing.

Rules for reading it:

- A fix version is **released** if its branch has a GA release with a version
  number greater than or equal to it. Example: 10.11 is at 10.11.18, so 10.11.18
  is released and 10.11.19 is not.
- A branch with no GA releases at all (a preview or not-yet-forked series, e.g.
  13.1) counts as **not released**.
- Never read the trailing `(YYYY-MM-DD)` on a `Fix versions:` line as a release
  date — it is the date the fix was pushed.

State in your final summary which releases you determined, so the user can spot a
stale lookup.

## 4. Decide each block

Apply in this order; first match wins.

| # | Condition | Verdict |
|---|-----------|---------|
| 1 | `NO MATCHES FOUND` | **KEEP** — always, unconditionally |
| 2 | Any `MENT-*` in the block | **KEEP** |
| 3 | `ATTENTION! FOUND CLOSED MDEV` present, and **at least one** fix version of **any** ticket named in that section is already released | **KEEP** |
| 4 | `ATTENTION! FOUND CLOSED MDEV` present, but **no** listed fix version is released yet | **REMOVE** |
| 5 | Anything else — passing `STATUS_OK` trials, blocks matching only unresolved MDEVs, blocks matching only `TODO-*` | **REMOVE** |

Notes:

- STRONG and WEAK match sections are treated identically; only the ticket kinds
  matter.
- Rule 3 is "any one released", not "all released": `Fix versions: 10.6.28
  10.11.19 ...` keeps the block if 10.6.28 has shipped, even though 10.11.19
  has not.
- A block whose ATTENTION verdict is KEEP stays even if it also lists unresolved
  MDEVs — it already earned a look.
- Rule 2 wins over rules 3–5 because MENT tickets are not publicly checkable.

**If a block does not fit any row above, or fits one only ambiguously — an
ATTENTION ticket with no `Fix versions:` line, a `RESOLUTION:` value other than
`Unresolved`/`FIXED`, a ticket prefix other than MDEV/MENT/TODO, a match section
with no entries — stop and ask the user.** Do not extend the rules on your own.
Report every such block together in one question rather than asking repeatedly.

## 5. Apply

Try hard to write commands in such a way so that they don't contain simple
expansions and similar elements requiring explicit permissions.

Avoid joining commands with ; &&, |, etc. when each command separately is allowed,
but your combination makes it require permissions.

```bash
python3 ~/.claude/skills/rqg-trial-filter/scripts/rqg_blocks.py <file> --keep 19,26,27,...
```

The kept blocks are copied through byte-for-byte; nothing is reformatted.

Then verify:

```bash
grep -c '^Trial: ' <file> <file>.bak
diff <(grep '^Trial: ' <file>) <(grep '^Trial: ' <file>.bak)
```

The surviving trial numbers must be exactly the set you passed to `--keep`, and
the diff must show only deletions.

## 6. Report

Give the user:

- kept N of M trials, with the kept trial numbers;
- one line per kept block saying why (`no matches`, `MENT-1234`, `MDEV-28404
  fixed in 10.6.28, released`);
- the release facts the ATTENTION decisions rested on;
- anything you had to ask about.

Keep it to a short table or list — the point is that the user can re-check your
release judgement at a glance.
