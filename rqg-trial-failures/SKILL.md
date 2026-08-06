---
name: rqg-trial-failures
description: Describe the unmatched failures in an RQG combo results file. The file holds blocks separated by ####### lines, each starting with "Trial: N"; blocks saying "NO MATCHES FOUND" have a trialN.log next to the file. Reads each such log and writes a one-few-line indicative description of the failure into the block, right after the NO MATCHES FOUND line. Use when asked to describe, annotate, label or summarise the failures in RQG results, combo results, or a results-*.txt trial file.
---

# Describe unmatched RQG trial failures

For every trial block that says `NO MATCHES FOUND`, read the matching
`trialN.log` and insert a short indicative description of the failure into the
block. Nothing else about the file changes.

The goal is a label a human can triage from — enough to recognise the failure and
tell it apart from the other trials in the run. Not an analysis: no root cause, no
hypotheses, no fix suggestions, no reproduction advice.

## 1. Get the file

The path comes in as the skill argument. If no argument was given, ask the user for
the path — do not guess, and do not scan the directory for candidates.

```bash
python3 ~/.claude/skills/rqg-trial-failures/scripts/rqg_annotate.py <file> --list
```

This prints one JSON record per block: `trial`, `status`, `no_matches_found`,
`described`, `existing_description`, `log`, `log_exists`, `log_gz_exists`.

If the script exits with `UNRECOGNISED STRUCTURE`, stop and show the user the
message — the file is not in the expected shape and guessing would corrupt it.

Work on the blocks with `no_matches_found: true`. Skip (and mention in the report)
any whose `described` is already true, unless the user asked to redo them.

Logs are sometimes kept compressed: `log_exists: false` with `log_gz_exists: true`
means only `trialN.log.gz` is there. Unpack it in place and carry on — no need to
ask:

```bash
gunzip <file's dir>/trialN.log.gz
```

The only place a trial log may come from is the directory holding the results file
given as the skill argument — `trialN.log` or `trialN.log.gz` there, and nowhere
else. Never look for logs in any other directory: not a parent, not a sibling run
directory, not anywhere a `find` might turn up a same-named file. A `trialN.log`
belonging to a different run would be described as if it were this one, which is
worse than no description at all.

When neither `trialN.log` nor `trialN.log.gz` is in that directory, the trial is
unreadable. Report the missing logs and ask the user how to proceed — do not search
for them, and do not guess at a description from the results file alone.

This skill only ever *adds* lines to the results file — never removes, reorders or
rewrites anything. So do not back the file up, do not copy it aside, and do not ask
the user for permission to modify it; just annotate it in place. (Its `<file>.bak`,
if one exists, belongs to `rqg-trial-filter` — leave it alone.)

## 2. Read each log

Each trial is independent, so process them concurrently where possible.

The interesting part of an RQG trial log is almost always near the end: the
`HIGHLIGHTS FROM .../mysql.err` section, the final `Test completed with failure
status ...` line, and whatever the server printed just before it. Start there, then
go back for the specific detail the status calls for. Do not read a multi-megabyte
log front to back.

Trust the block's `Status:` over your own reading of the log — that is the verdict
RQG reached.

## 3. Write the description, per status

Below is what to extract for each status.

For a status that **is** listed below, write the description and apply it without
asking. No confirmation step, no proposing it first — that is the whole job.

For a status that is **not** listed below, the skill has never handled that kind of
failure. Analyse the log anyway, then show the user the status, the trial number and
the description you propose, and get their confirmation before writing it. They may
want a different angle, and the run is only comparable if a status always reports the
same way. Collect all such blocks into one question rather than asking repeatedly,
and once the shape is agreed, offer to add a section for that status here.

For each case, if there are no expected and described elements for the failure,
make the best guess for the cause of the failure from the available logs. Make
a note in the verdict that the representation was unusual and you were guessing.


### STATUS_SERVER_UNAVAILABLE, STATUS_SERVER_CRASHED

Search for assertion failures, mutex errors, stack traces or sanitizer reports.
If found, report (each on a separate line):

- the error kind, with the access size / signal / assertion text as printed;
- the innermost meaningful frame — function plus `file.cc:line`;
- the two-to-four frames above it that say what the server was doing, named as
  functions; collapse the boilerplate (`mysql_parse`, `dispatch_command`,
  `do_command`, `tp_callback`, `pfs_spawn_thread`) into what the statement was,
  e.g. "on SELECT", "during ALTER".
- if the crashing query is visible in the error log or in the stack trace,
  report it as well. If the query is very long, drop its middle.

For a sanitizer report, use the reporting stack (the one under `READ of size` /
`WRITE of size`), not the allocation or thread-creation stacks that follow it.


### STATUS_ERRORS_IN_LOG

The server survived, but wrote lines to `mysql.err` that RQG flags. The
description is: what the error log said, plus what triggered it.

Find the `[ERROR]` lines in the highlights section — they sit between the
`Starting MariaDB` / `Version:` notes and the shutdown notes, so the surrounding
notes are not part of the finding. Then grep the whole trial log for the same
error text or error number: a worker usually reports the same condition as a query
status (`WRK-N: STATUS_..._ERROR: <errno> "..."`) together with the statement that
hit it, which is what lets you say what triggered it.

Report:

- SAN errors: The error itself, followed by stack trace reporting;
- the stack trace: several meaningful frames after "signal handler" or such,
  one frame per line, drop the address, keep the frame number, the function,
  the file/line when available;
- the error number and message text as printed, and the object it names — file,
  table, index, tablespace;
- the statement kind that raised it, when a worker line shows one — "on a DELETE
  against that table", not the whole query;
- the storage engine when the log makes it plain (a `.MAI`/`.MAD` file is Aria, an
  `.ibd` file InnoDB).
- ignore the line Can't open shared library ... server_audit2.so ... No such file or directory

If the same event typically appears several times in the logs, name it once.
Do not count those copies as separate errors.

Ignore the per-executor `Errors: for Executor#N: 0: ... 1054: ...` histograms and
the `Health stats:` totals. Those are ordinary query errors from the workload, not
the reason the trial failed.

If the log holds many similar error lines, do not quote all of them. Say what kind
they are, roughly how many, and what they range over — "dozens of ... across
several tables" — and name the distinct kinds only.

### STATUS_DATABASE_CORRUPTION

Usually RQG's own verdict, not the server's. It is either a certain SQL error code
which RQG interprets as corruption, or an error coming from a reporter/validator.
Search for DATABASE_CORRUPTION in the trial log, usually the guilty query is
either on the same line or directly before/after. If there are many similar
corruption errors, do not quote all of them, summarize the results.

If instead the server itself reported the corruption in `mysql.err` — an InnoDB or
Aria corruption message — describe it from the server's own wording.

Example, from a trial whose corruption was found by a reporter:

### STATUS_CONTENT_MISMATCH, STATUS_LENGH_MISMATCH

The errors come either from comparison tests, when the same query is executed
on two different servers and results are compared, or from transformation tests,
when a query is executed, then transformed into something with a predictable
result (e.g. identical result set, or superset, or subset, etc.) and executed
again. The error happens when the expectations are not met.

Search for MISMATCH in the trial log.

Report the query, the type of mismatch (length or content), the number of different
lines if applicable. If it is a transformation, report the transformer name.
Do not report the whole diff.

If there are many mismatches, do not report all of them, only give the count and
a short summary.

### STATUS_SERVER_STARTUP_FAILURE

The server didn't start at some point. Search for a reported reason, usually it
is an ERROR and abort on startup. Sometimes it can be too slow recovery and
RQG gives up waiting. If no obvious errors, pay attention to timestamps.

### STATUS_SERVER_SHUTDOWN_FAILURE

The server didn't shut down properly. Search for a reported reason. Usually it
will be just vague "couldn't TERM, doing KILL" or alike. Sometimes it can also
be crash on shutdown or sanitizer errors.

### STATUS_RECOVERY_FAILURE, STATUS_UPGRADE_FAILURE

The failure can be similar to in nature to other status types --
STATUS_DATABASE_CORRUPTION, STATUS_SERVER_STARTUP_FAILURE,
STATUS_SERVER_UNAVAILABLE, STATUS_SERVER_CRASHED, STATUS_ERRORS_IN_LOG,
but happening in the context of crash recovery or restart/upgrade. If so,
report it accordingly. Otherwise specific reasons could be a failure
upon creating a database dump, a failure upon restoring the database dump,
or unexpected differences after restoring the dump. Search for them,
report the type. If the failure is a difference and the diff is 2-liner,
quote it. If the diff is long, just describe it, do not quote it. If there are
several diffs of the same kinds, summarize them.

### STATUS_BACKUP_FAILURE

Can be either a failure similar to previous ones, when the contents of the backup
is different from the original dataset, in this case process it the same way
as already described; or, it can be an error upon mariabackup execution of
--backup or --prepare, then find and extract the error. It can also be too
long backup/prepare when the test gives up waiting, normally in this case the
test should say something about backup not finishing in time.

### STATUS_REPLICATION_FAILURE

Can be either a diff between master and slave, or replication abort due to an error
on the slave. If it is an error, report it. If it is a diff, report it in a similar
way as for STATUS_RECOVERY_FAILURE / STATUS_UPGRADE_FAILURE.

### STATUS_REPLICATION_TIMEOUT

Can be either a genuine timeout or replication failure misinterpreted as a timeout.
Check which it was, report it. If a reason for the timeout was given, report it
as well.

### STATUS_PERL_FAILURE

Usually a Perl error, can be either a genuine RQG bug or any other failure leading
to a Perl error as a side-effect. If there is an underlying failure, report it.
In either case, report the Perl error too.

### STATUS_CLIENT_FAILURE

Unless miscategorized, there should be a statement execution error marked as
STATUS_CLIENT_FAILURE in the trial log, report it. If there are many similar errors,
summarize.

### STATUS_CRITICAL_FAILURE, STATUS_ENVIRONMENT_FAILURE

Can be most of other status types but converted into a different status on some
reason, or a failure which RQG could not otherwise categorize. See for other types
and reasons; if not found, see the errors written by the test immediately preceeding
declaring the status; if not found, try to guess.

## 4. Style

- One to a few lines. Try to keep it compact but don't trade the number of lines
  for readability.
- Plain text — the target is a `.txt` file, so no backticks, bold, bullets or
  other markdown.
- Concrete over generic: function names, file:line, error numbers, sizes. 
- Copy identifiers exactly as the log spells them. Never reconstruct a line number
  from memory.
- **Every description must stand on its own.** A reader looking at one block must
  learn what the failure was without reading any other block. So spell the finding
  out in full every time, even when an earlier trial in the same run carries the
  identical one:
    - an error number always comes with its message text — error 1034 "Index for
      table 'tmp' is corrupt; try to repair it" — never "the same 1034 as trial 24",
      and never a bare "failed with 1055";
    - an assertion always comes with the assertion text, and a crash always with
      its innermost frame and the frames above it — never "same assertion and stack
      as trial 16";
    - a reporter finding always names the reporter, the object and the evidence.
- Repeat identical findings rather than cross-referencing them, but do keep the
  cross-reference as an addition once the description is complete: a closing "Same
  assertion and stack as trial 16." after the full text is useful triage
  information, because it tells the reader the two trials are one failure. It just
  may never stand in place of the text itself.
- Describe the failure, not the outcome. The block already carries the `Status:`
  line, so do not restate it or its consequences — no "server aborted", no
  "→ STATUS_ERRORS_IN_LOG", no coredump-present-or-absent note, no scope tallies
  like "one table only".
- No speculation. If the log does not say what happened, say what it does show
  and no more.

## 5. Apply

Try hard to write commands in such a way so that they don't contain simple
expansions and similar elements requiring explicit permissions.

Avoid joining commands with ; &&, |, etc. when each command separately is allowed,
but your combination makes it require permissions.

Write the descriptions to a JSON file in the scratchpad, keyed by trial number as
a string:

```json
{
  "32": "...",
  "93": "ASAN use-after-poison (READ of size 489) in Field::print_key_part_value ..."
}
```

Then:

```bash
python3 ~/.claude/skills/rqg-trial-failures/scripts/rqg_annotate.py <file> --apply <scratchpad>/desc.json
```

Each description lands after that block's `NO MATCHES FOUND` line with a blank
line before it. Blocks not named in the JSON pass through byte-for-byte. The script
refuses a block that already has a description; add `--replace` only if the user
asked for the old one to be overwritten.

Verify:

```bash
python3 ~/.claude/skills/rqg-trial-failures/scripts/rqg_annotate.py <file> --list
```

Every trial you described must now read `described: true`, and the set of trial
numbers must be unchanged from step 1.

## 6. Report

List the trials you described, one line each: trial number, status, and the
description. Then note separately anything you skipped — already described, log
missing — and why.
