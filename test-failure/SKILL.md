---
name: test-failure
description: Reproduce an RQG or MTR failure, create a minimal reproducer,
             find the guilty commit when possible. Use when asked to analyze
             a test failure.
---

# Processing a test failure

**STOP — read this before your first tool call.**
The invocation argument is expected to contain two values. First is the source of
the failure, either RQG or MTR. The second is a path to a directory containing
information related to the failure. The contents of the directory will depend
on the source of the failure, but in any case there will be a signature
of the failure that needs to be reproduced.
In this skill you **must stick to the failure described in the signature**.
For example, if the signature says that the failure is a crash with a certain
frame(s) in the stack trace, your resulting reproducer must cause a crash containing
the given frames, not some other crash. There can be different types of failures,
but the same principle applies: whatever is described specifically needs to be
kept as is.
You must **never digress to a different failure**, not even as a parallel
investigation. If you encounter a different failure worth attention, make a note
of it in the final analysis, but do not spend any resources whatsoever trying
to reproduce or otherwise analyze it.

## Step 0 — check arguments, fill the gaps

**This step is mandatory and it is a hard gate.**

The first argument must be "MTR" or "RQG". If it is missing or is something else,
stop immediately and `AskUserQuestion`:

* **What type of failure am I analysing?** The answer options should be "MTR",
  "RQG", and "something else, explain".

After the first argument is checked, the second argument must be a path
to an existing directory. If it was not provided, or does not exist, or is not
a directory, stop immediately and `AskUserQuestion`:

* **Where is the failure directory?** The answer options should be
  "I will provide the path", "Stop execution".

For the failure type "RQG" only: If the directory exists but does not contain
a file named "signature.txt", stop immediately and `AskUserQuestion`:

* **Provide failure signature** The answer options should be "I will provide the path",
  "I will provide the description", "Guess from the logs".

For the failure type "MTR" only: If the directory exists but does not contain
a file with the extension .test, stop immediately and `AskUserQuestion`:

* **Provide MTR test** The answer options should be "I will provide the path",
  "Stop execution".

For the failure type "MTR" only: If the file with the extension .test exists,
but there is no file signature.txt and the file with the extension .test
does not have a line containing "Failure output: " or "Search pattern(s)"
among the first 5 lines of the file, stop immediately and `AskUserQuestion`:

* **Provide failure signature** The answer options should be "I will provide the path",
  "I will provide the description", "Guess from the logs".

**You must not proceed until the failure type, directory, and signature are clarified**.
If you have already started running other tools but you don't have this information,
stop and ask for it now. In case of MTR, the part of the line after "Failure output: "
counts as a signature, or the part of the line after "Search pattern(s): " counts
as a regexp of the signature.

## Step 1 — analyze the contents of the failure directory

Depending on the failure type and other circumstances, the contents of the
directory can be very different.

An RQG trial directory typically looks like:

```
/<provided path>/
├── trial<N>.log            # the RQG log (may be .gz / .xz / inside a tarball)
└── vardir<N>/              # (may be compressed)
    ├── rqg.<sha>.diff      # local RQG modifications, if any
    └── s1/
        ├── data/           # datadir at the moment the trial ended
        ├── tmp/            # server tmpdir
        ├── mysql.err       # server error log
        ├── mysql.log       # GENERAL QUERY LOG — the single most valuable artifact
        ├── boot.sql, boot.log
        └── metadata/, *-metadata-*   # RQG metadata dumps
    ...
```

Multi-server scenarios (replication, upgrade) can have `s1`, `s2`, …

**The layout will not always match this.** File and directory names vary between
RQG versions, combination setups and how the artifacts were archived.
Do not treat a mismatch as a problem or a reason to stop — look
around (`find <dir> -maxdepth 3`, decompress what is compressed), identify which
file plays which role, and carry on. Say which files you settled on.

In case of an MTR failure directory will likely contain a file <filename>.test,
server error logs mysqld.N.err, and possibly other logs.

```
/<provided path>/
├── <filename>.test         # the MTR test to improve
└── mysqld.1.err            # server error log
└── stdout.log              # test output
  ...
```

## Step 2 — pre-process RQG logs

**Skip in case of an MTR failure**

Orient in the trial log:

```sh
head -40 <trial>.log                  # RQG revision, full command line, scenario
grep -n "Test completed with failure status\|Test run ends with" <trial>.log
grep -n "\[ERROR\]" <trial>.log | head -50
```

Extract and write down:

* the RQG revision (`RQG git revision <sha>`) and which checkout it maps to
  (`/data/src/rqg*`, plus any `rqg.<sha>.diff` in the vardir);
* the **scenario** (`=== CrashRecovery scenario ===`, `Standard`, `Upgrade`,
  replication, …) — it determines what the reporters see and when;
* the reporter list, grammars, `--gendata`, `--threads`, `--duration`, seed;
* every `--mysqld=` option (they change timing and code paths: `--log-bin`,
  `--max-statement-time`, `--lock-wait-timeout`, isolation level, …);
* the **build type** of the server that failed (`13.1.0-MariaDB-asan-log` in the
  banner means ASAN — see *Timing* below).

Decide whether the failure is real before chasing it:

This is the step most often skipped and most often decisive. Reporters run at
fixed points; a scenario that aborts early can run end-of-test reporters against
a server that is dead, half-recovered, or not the one you assume.

Checklist:

* Read the scenario module (`lib/GenTest/Scenario/*.pm` in the RQG checkout) and
  trace the exact path the trial took. An early `goto FINALIZE` still runs all
  `REPORTER_TYPE_END` reporters.
* Read the reporter that fired (`lib/GenTest/Reporter/<Name>.pm`) — what does it
  actually check, and does it assume a live and recovered server?
* Compare timestamps in the RQG log against `mysql.err`. An `[ERROR]` logged
  *during* the test flow is a different problem from one logged during shutdown,
  and RQG's log-checking helpers do not always scope the window the way their
  step names suggest — read the helper rather than trusting the step name.
* Where possible, **test the assumption directly rather than reasoning about
  it**. The datadir is right there: copy it and start a server of the same
  revision on the copy. That single experiment answers most "is this really
  damage?" questions — leftover temporary or in-flight DDL files are removed by
  ddl_log crash recovery and by the tmpdir cleanup at startup, so if they vanish
  on restart they were never orphans, and the reporter simply ran before the
  restart it was written to follow.

If the reported failure turns out to be a harness artifact, say so plainly, name
the underlying real failure if there is one, **stop** and ask for further
instructions. Do not re-target the investigation.

Mine the artifacts:

`mysql.log` (the general query log) is usually the key. It records every
statement of every connection with its connection id, so you can:

* find what the connection named in an `mysql.err` error was doing
  (`2026-08-07 17:04:47 13 [ERROR] …` → connection **13**);
* recover the exact statement stream for replay.

`scripts/split_genlog.pl` (bundled with this skill) splits a general log into one
replayable `.sql` file per connection for a time window:

```sh
perl ~/.claude/skills/test-failure/scripts/split_genlog.pl <vardir>/s1/mysql.log /data/local/replay 17:03:30 17:04:51
```

Replaying the recorded streams concurrently against a server started on the
trial's own datadir is a possible reproduction attempt: it is the real statement
mix rather than an imitation of it. However, since it will likely have a broken
timing, evaluate whether it is suitable for the target failure instead of using it
blindly.

Other useful sources: `mysql.err`, the datadir itself (file names and mtimes —
temporary DDL names encode pid/thread/counter, and an mtime equal to the kill
second tells you the statement was in flight), `*-metadata-*` dumps, binlogs
(`mariadb-binlog`), and `ddl_recovery.log`.

## Step 3 — extract information from the MTR test

**Skip in case of an RQG failure**

The directory will contain a <filename>.test file which will likely have
the first lines similar to

```
# Remaining options: --mysqld=--loose-plugin-innodb --mysqld=--loose-plugin-innodb-sys-tablestats
# Basedir: /data/bld/13.0-debug
# Search pattern(s): (?^s:TABLE_SHARE::db_type)
```
or they may look like
```
# Server options: --mysqld=--max-allowed-packet=1G --mysqld=--loose-innodb-ft-min-token-size=10 --mysqld=--secure-file-priv= --mysqld=--loose-debug-assert-on-not-freed-memory=1
# Failure output: "marked as crashed and should be repaired"
# Initial server: /data/bld/main-rel//sql/mysqld, Version: 13.1.0-MariaDB-log (MariaDB Server)
```

If "remaining options" or "server options" are provided, use them to run the
test case via MTR.

Unless the directory contains a file named "signature.txt", use the part of the
line after "Failure output: " as a signature, or the part of the line after
"Search pattern(s): " as a regexp of the signature. If signature.txt is provided,
ignore the lines.

Only use the "Basedir" or "Initial server" information when you don't have
any other information about the server branch / revision which was used for
the test, otherwise ignore.


## Step 4 — find or create a suitable build

If a path to a source tree is given inside signature.txt, use it.

Otherwise, if you have the server error log, extract the server revision from it,
the server writes it upon startup. Otherwise assume that it is a top of the branch
corresponding to the server version.

If you only need code for reading, you can search for a suitable clone under
CLAUDE_EXTERNAL_SOURCES (read-only). Alternatively, you can clone/fetch it
from Github inside CLAUDE_BUILD_DIR and optionally check out the revision from
the error log.

If you need a build of a certain type, you can build it under CLAUDE_BUILD_DIR.
You can do any modifications to your own clones and builds under CLAUDE_BUILD_DIR.

Choose the build type deliberately: `Debug` for `--debug-dbug` crash points and
assertions, `-DWITH_ASAN=ON` to match an `-asan-log` trial's timing. Builds are
long — start them in the background and keep investigating meanwhile.

### Timing matters more than you expect

If the trial ran an **ASAN** build (`-asan-log` in the version banner) and you
only have a RelWithDebInfo build, races interleave completely differently and may
simply not reproduce. Building an ASAN server of the same revision is often a
better use of time than a fifth stress variant.


## Step 5 — reproduce

**IMPORTANT**
You must **never digress to a different failure** from the signature that
you were given.
If you encounter a different failure worth attention, make a note
of it in the README, but do not spend any resources whatsoever trying
to reproduce or otherwise analyze it, step back to the original one.

If the failure type is MTR, the deliverable is always an MTR test, derived
from the one originally provided.

In case of the failure type "RQG", preference order for the deliverable:

1. **MTR test** — best. Write it whenever the failure is deterministic and
   single/few-session, and **run it** — `mariadb-test-run.pl` works in this
   sandbox provided you pass `--build-thread=<N>` (see *Environment*).
   Non-deterministic MTR test cases which reproduce the failure within a
   reasonable number of attempts (--repeat=N) is also acceptable.
   Do not attempt to record the result file.
   Mind the build: crash points in `sql/*.cc` need a `-DCMAKE_BUILD_TYPE=Debug`
   build; a RelWithDebInfo build has `DBUG_OFF` and no `--debug-dbug`.
2. **RQG grammar + command line** — the right answer for concurrency-driven
   failures. Start from the trial's own grammars, then *narrow*: remove one arm
   or ingredient at a time, run each variant to a fixed query budget, and record
   a table of variant → queries run → hits. Keep the ablations that reach zero
   hits; they are the proof of which ingredients are required, and they are as
   valuable as the positive case. `--mysqld=--debug-no-sync` is often essential
   to reach the query throughput of the original trial — fsync latency can hold a
   run to a small fraction of the original's query count, and nothing reproduces.
3. **Another reproducer** — a shell/Perl harness driving several client
   connections, or a replay of the recorded statement streams.
4. **Verbal description** — the exact conditions, and why automating them is hard.
5. **Explanation of why it is impossible or shouldn't be done** — a legitimate
   outcome, e.g. when the failure is a harness artifact.

Always report negative results with their scale ("1536 single-connection cases,
no hit"; "4 rounds × 900 s of the recorded streams, no hit"). They narrow the
problem for whoever picks it up next. Prefer an exhaustive cheap matrix
(engine × option × statement shape, checking the error log after each case) over
a handful of hand-picked guesses: it either finds the case or rules out the whole
class, and either result is worth reporting.

## Step 6 — simplify and cleanup

**Skip if the deliverable is not an MTR test**

Remove as many unnecessary elements from the MTR test as possible as long
as it still reproduces the target failure (never retarget to a different one).
It applies to all of
* statements
* lines
* inserted values
* indices
* table columns
* table options and attributes
* column options and attributes
* query parts (GROUP BY, ORDER BY, WHERE, etc.)
* statement parts (for example, different ALTER parts)

Note that some elements are co-dependent, for example if you remove a column
from a table, you might need to re-write following INSERT statements, etc.

Use standard short table names (t1,...), short view names (v1,...) short column
names (one-letter names or f1,....), etc.

When possible, replace sequences of statements with a statement which achieves
the same result. For example, if the test case contains CREATE TABLE followed
by various ALTER TABLE, it is often possible to replace the whole chain with
a single CREATE TABLE with the structure which all ALTERs lead to.

Attempt to remove server and MTR options which you were using to reproduce
the failure. When possible, replace the command-line options with MTR's
includes, explicit dynamic variable SETs, table elements, etc.

## Examples:

* `--mysqld=--innodb` (`--mysqld=--loose-innodb`) option can usually be replaced
  with `--source include/have_innodb.inc` call at the beginning of the test case;

* `--mysqld=--default-storage-engine=XXX` can usually be replaced with explicit
  `ENGINE=XXX` in table creation statements where the engine is not specified;

## Step 7 — search for existing JIRA items

If there is an open JIRA issue which reports the exact failure you have
reproduced, report it in the final README.

## Step 8 — check versions

With deterministic or nearly deterministic reproducers, check which main
branches are affected (e.g. 10.6, 11.4, etc). The lowest version to check is 10.6,
and further all currently active LTS versions, the current RC, and the main branch.
For checking versions, you can use CLAUDE_EXTERNAL_BUILDS/ if there is a suitable
build, and only build in CLAUDE_BUILD_DIR when necessary.

## Step 9 — find the guilty revision

If you can find out the guilty revision by code inspection, do so. Otherwise,
in case of deterministic reproducers, use git bisect to find the revision
which caused the failure. Stick to the original signature, that is, search for
the revision which caused **the specific failure**, even if the test case
was failing in a different way before the reivison.

## Environment

### Running servers in this sandbox

Unix domain sockets **work** here (`sandbox.network.allowAllUnixSockets: true`),
so MTR, RQG and hand-started servers all run normally. Confirm in one line
before relying on it, because the setting can change:

```sh
python3 -c "import socket; socket.socket(socket.AF_UNIX); print('AF_UNIX OK')"
```

If that raises `PermissionError: [Errno 1] Operation not permitted`, the old
seccomp block is back — read *If AF_UNIX is blocked again* at the end of this
section and follow it instead of the rest.

**MTR** — works, including `--parallel` and multi-server suites (`rpl.*`,
`innodb.*` verified), with **one mandatory flag**:

```sh
cd $BLD/mysql-test
perl ./mariadb-test-run.pl --build-thread=400 --vardir=/data/local/mtr-var main.select
```

`--build-thread=<N>` (or `MTR_BUILD_THREAD=<N>`) is required. Without it MTR
allocates a build thread through `lib/mtr_unique.pm`, which hard-codes
`/tmp/mysql-unique-ids` on Linux with no env override; `/tmp` is not writable in
the sandbox, so the run dies with `can't make directory /tmp/mysql-unique-ids at
lib/mtr_unique.pm line 89` before the first test. Any N works (ports are
`N*10+10000`); each Bash invocation has its own network namespace, so concurrent
invocations cannot collide on ports even with the same N.

So MTR tests are now first-class deliverables: **write them and run them**, and
report the actual result rather than marking them unverified.

**RQG** — works with a stock, unmodified checkout; the old `socketfile()` patch
is obsolete. `/data/src/rqg*` is read-only but RQG does not need to write into
its own tree, and `--grammar=` accepts an absolute path outside it, so there is
no reason to make a writable copy just to add a grammar:

```sh
cd /data/src/rqg
perl ./run.pl --basedir=/data/bld/<build> --vardir=/data/local/rqgvar1 \
  --grammar=/data/claude-work/<topic>/repro/min.yy --threads=4 --duration=300
```

**Hand-started server** — start it with a real `--socket=` and use it:

```sh
$BLD/sql/mariadbd --no-defaults --basedir=$BLD --lc-messages-dir=$BLD/sql/share \
  --datadir=$DD/data --tmpdir=$DD/tmp --port=$PORT --socket=$DD/my.sock \
  --log-error=$DD/err.log ... &
for i in $(seq 1 60); do
  $BLD/client/mariadb --socket=$DD/my.sock -uroot --connect-timeout=1 \
      -e "select 1" >/dev/null 2>&1 && break
  python3 -c "import time;time.sleep(0.5)"
done
```

`scripts/start-server.sh` in this skill does this, including a driver hook.

Notes that cost real time if forgotten:

* **Keep every vardir/datadir path short.** A socket path over 107 characters
  fails with `The socket file path is too long (> 107)`. The session scratchpad
  path is 95 characters, so `<scratchpad>/s1/mysql.sock` (109) is already too
  long — **do not use the scratchpad for datadirs or RQG/MTR vardirs.** Use
  `/data/local/<short>` instead.
* **A background server is reachable from later invocations, but only over its
  unix socket.** Start it with `run_in_background`, then connect from any later
  invocation with `--socket=<path>`. TCP does *not* cross invocations (each gets
  its own network namespace, so `127.0.0.1:<port>` gives connection refused —
  which looks exactly like a policy block and will mislead you), and neither do
  PIDs (`kill` reports no such process, `/proc/<pid>` does not exist). Shut such
  a server down with `mariadb-admin --socket=<path> -uroot shutdown`, not `kill`.
* A server backgrounded with plain `&` inside a normal Bash invocation is killed
  when that invocation ends. Either keep server and clients in the same
  invocation, or start the server with `run_in_background` and drive it over the
  socket from subsequent invocations.
* **Poll with the client, not with the log.** Waiting for `ready for
  connections` to appear in the error log and then connecting once is fragile;
  retry the client in a loop.
* **`wait` with no arguments also waits for the server**, which never exits.
  Collect client PIDs and `wait $pids`.
* Foreground `sleep` is blocked; use `python3 -c "import time;time.sleep(N)"`
  or `perl -e 'select(undef,undef,undef,0.5)'`.
* If the datadir needs authentication, connect over the socket as `root` (a
  bootstrapped datadir has `root@localhost`, which is what a socket connection
  authenticates as), or start with `--skip-grant-tables` when ACLs are
  irrelevant. Do **not** use `--skip-grant-tables` if the workload's ACL errors
  are part of the failure — RQG grammars that `REVOKE` privileges depend on them.
* MTR suite names should not contain dashes, so instead of pointing MTR at a
  directory with a dash as a suite, use symlinks or keep MTR test cases under
  CLAUDE_CODE_TMPDIR/bug and only copy them to the final delivery folder
  at the end.
  

**If AF_UNIX is blocked again** (the check above fails): a seccomp filter makes
`socket(AF_UNIX, …)` return `EPERM`. Then `mariadbd` must be started with an
*empty* `--socket=`, which makes `sql/mysqld.cc` skip unix-socket creation, and
clients must use `--protocol=tcp -h 127.0.0.1 -P$PORT` — server and clients in
the same Bash invocation, since TCP does not cross invocations. RQG needs a
writable copy of the checkout with `reference/rqg-no-unix-socket.patch` applied
(`socketfile()` returns empty under `RQG_NO_UNIX_SOCKET=1`). MTR cannot run at
all in that mode: deliver the test, mark it explicitly unverified, and **stop —
do not try to work around it.** The block can only be lifted outside the
session, via `sandbox.network.allowAllUnixSockets: true` in
`~/.claude/settings.json`; that is the user's call and it has real security cost
(it exposes whatever unix sockets the session can reach — `SSH_AUTH_SOCK`, the
D-Bus session bus, X11). Mention it as an option if MTR verification would
genuinely change the outcome; do not enable or advocate for it.

### Scratch space

Use `/data/claude-work/<directory name>/` (where <directory name> is the
basename of the failure directory you were given to investigate)
for deliverables and `/data/local/` for datadirs and vardirs.
Not the session scratchpad: its path is long enough
that a server's socket path inside it exceeds the 107-character limit. Datadir
copies run to hundreds of MB each; clean them up when done.

## Deliverable

Write the result to `/data/claude-work/<directory name>/` with:

* `README.md` — the verdict up front, then the evidence chain
  (log excerpts with timestamps, code pointers as `file:line`), then the
  reproducer and its hit rate, then negative results and their scale,
  then all side notes that you collected (e.g. different failures you
  encountered);
* the reproducer itself (MTR `.test`, `.yy` grammar + runner script,
  or harness scripts) with everything needed to re-run it;
* any harness scripts used, so the next person does not have to rebuild them.

State plainly what was verified and what was not.
