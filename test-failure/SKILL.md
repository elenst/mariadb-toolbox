---
name: test-failure
description: Analyse a failure, produce a minimal reproducer when possible, find a guilty commit when possible. 


arguments:
- failure source (RQG or MTR)




Use when given a directory holding an RQG trial log and its vardir/logs (possibly compressed) — e.g. "analyse the failure in /data/tmp/<trial>", "why did this RQG trial report corruption", "make a test case for this RQG trial". Produces, in order of preference, an MTR test, an RQG grammar + command line, another reproducer, a verbal test description, or a justified explanation of why no reproducer is possible or worthwhile.
---

# Analysing an RQG trial failure

> **STOP — read this before your first tool call.**
> The **first tool call you make in this skill must be the `AskUserQuestion` of
> [Step 0](#step-0--ask-first-investigate-second)**. Not `find`, not `ls`, not
> `head`, not `tar`, not `git`. Everything below Step 0 assumes the user has
> already told you which failure to chase and where the tree is; reading it
> first is how you end up guessing.
> If you have already run a tool in this skill without asking: stop and ask now,
> before the next one.

An RQG trial directory typically looks like:

```
/data/tmp/<combination>-<trial>/
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
```

Multi-server scenarios (replication, upgrade) have `s1`, `s2`, …

**The layout will not always match this.** File and directory names vary between
RQG versions, combination setups and how the artifacts were archived: the log may
be `trial37.log`, `rqg.log`, `*.log.gz` or a member of a tarball; the vardir may
be `vardir37/`, `vardir/`, `var/` or a tarball; the server subdirectory may be
`s1/`, `1/` or absent for single-server runs; the general log may be disabled
altogether. Do not treat a mismatch as a problem or a reason to stop — look
around (`find <dir> -maxdepth 3`, decompress what is compressed), identify which
file plays which role, and carry on. Say which files you settled on.

## Step 0 — ask first, investigate second

**This step is mandatory and it is a hard gate.** It is not "ask if unsure", not
"ask unless the answer looks obvious", and not "orient first, then confirm".
Ask *before your first tool call in this skill* — before `find`, `ls`, `head`,
`tar`, `grep`, `git`, before opening the trial log at all. You have no
legitimate reason to touch the trial directory before you know which failure
you were handed.

**Before doing anything else, ask the user one question** (a single
`AskUserQuestion`) that covers both of these, so it can be answered in one go:

* **Which failure am I analysing?** RQG's reported status is often vague — the
  same `STATUS_DATABASE_CORRUPTION` can come from a reporter finding stray files,
  from error 1194 being raised on a healthy table, from a `CHECK TABLE` result,
  or from a consistency reporter. A trial can also contain several independent
  problems. Offer *"you tell me"* vs *"guess from the trial log"*; if told to
  guess, state explicitly which one you picked and why before proceeding.
* **Where is the source tree** (and any matching build)? Optional — see
  *Getting a source tree and a build* if it is not provided.

Phrase it as one question with options covering both, and make clear that a
free-form answer giving the failure and the path together is welcome.

Do not skip this. Picking the wrong failure wastes the whole investigation.

### Things that are NOT permission to skip Step 0

None of the following lets you start investigating without asking. If any of
them happens, ask the Step 0 question anyway, as your very next action:

* **"proceed" / "go ahead" / "continue"**, whether typed by the user or arriving
  after an interrupted tool call. It means *carry on with the skill*, and the
  next thing the skill says is *ask*. It does not answer "which failure?".
* **A trial with only one visible failure.** "Only one crash in the log" is your
  reading of the log, not the user's answer; the user may care about an earlier
  symptom, a known-bug duplicate, or the reason the trial got that far at all.
* **A very obvious-looking assertion or backtrace.** The more obvious it looks,
  the cheaper the question is to ask.
* **Having already peeked at the log** (e.g. through an earlier turn, or because
  you jumped the gun). Stop and ask, then continue.
* **Announcing your pick in prose** ("the failure is unambiguous, it's X").
  Stating a guess is not the same as asking, and it is exactly the shape of the
  mistake this step exists to prevent.

The only case where you may proceed without a fresh `AskUserQuestion` is when
the user has *already*, in this conversation, named the failure **and** told you
where the source tree is. If they gave one but not the other, ask for the other.

## Step 1 — orient in the trial log

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

The sibling skills `rqg-trial-filter` and `rqg-trial-failures` summarise a whole
combinations results file; use them when handed many trials rather than one.

## Step 2 — decide whether the failure is real before chasing it

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
the underlying real failure if there is one (an early abort is usually caused by
something), and re-target the reproducer at it.

## Step 3 — mine the artifacts

`mysql.log` (the general query log) is usually the key. It records every
statement of every connection with its connection id, so you can:

* find what the connection named in an `mysql.err` error was doing
  (`2026-08-07 17:04:47 13 [ERROR] …` → connection **13**);
* recover the exact statement stream for replay.

`scripts/split_genlog.pl` (bundled with this skill) splits a general log into one
replayable `.sql` file per connection for a time window:

```sh
perl scripts/split_genlog.pl <vardir>/s1/mysql.log /data/local/replay 17:03:30 17:04:51
```

Replaying the recorded streams concurrently against a server started on the
trial's own datadir is a strong reproduction attempt: it is the real statement
mix rather than an imitation of it.

Other useful sources: `mysql.err`, the datadir itself (file names and mtimes —
temporary DDL names encode pid/thread/counter, and an mtime equal to the kill
second tells you the statement was in flight), `*-metadata-*` dumps, binlogs
(`mariadb-binlog`), and `ddl_recovery.log`.

## Step 4 — reproduce

Preference order for the deliverable:

1. **MTR test** — best. Write it whenever the failure is deterministic and
   single/few-session, and **run it** — `mariadb-test-run.pl` works in this
   sandbox provided you pass `--build-thread=<N>` (see *Environment*). Record
   the actual result, including the `.result` file it produced. Mind the build:
   crash points in `sql/*.cc` need a `-DCMAKE_BUILD_TYPE=Debug` build; a
   RelWithDebInfo build has `DBUG_OFF` and no `--debug-dbug`.
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

### Timing matters more than you expect

If the trial ran an **ASAN** build (`-asan-log` in the version banner) and you
only have a RelWithDebInfo build, races interleave completely differently and may
simply not reproduce. Building an ASAN server of the same revision is often a
better use of time than a fifth stress variant.

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

### Getting a source tree and a build

* **Use the source tree you were given.** Clone only when you actually need to:
  no tree was provided, the provided tree is at the wrong revision, or you need
  to modify sources (e.g. instrument an error site) and must not touch the user's
  tree. In that case `github.com` is reachable:
  `git clone https://github.com/MariaDB/server /data/src/<name>`, then check out
  the revision from the trial log's `source revision <sha>` banner.
* **Never modify the user's source tree or build** without asking.
* **No suitable build?** Check `/data/bld/*` for one matching the trial's
  revision first. If there is none, build one under `/data/bld` (writable, tens
  of GB free):

  ```sh
  mkdir -p /data/bld/<name> && cd /data/bld/<name>
  cmake /data/src/<name> -DCMAKE_BUILD_TYPE=Debug   # or RelWithDebInfo
  make -j$(nproc)
  ```

  Choose the build type deliberately: `Debug` for `--debug-dbug` crash points and
  assertions, `-DWITH_ASAN=ON` to match an `-asan-log` trial's timing. Builds are
  long — start them in the background and keep investigating meanwhile.

### Scratch space

Use `/data/claude-work/<trial-id>-<topic>/` for deliverables and `/data/local/`
for datadirs and vardirs. Not the session scratchpad: its path is long enough
that a server's socket path inside it exceeds the 107-character limit. Datadir
copies run to hundreds of MB each; clean them up when done.

## Deliverable

Write the result to `/data/claude-work/<trial-id>-<topic>/` with:

* `README.md` — the verdict in one paragraph up front, then the evidence chain
  (log excerpts with timestamps, code pointers as `file:line`), then the
  reproducer and its hit rate, then negative results and their scale;
* the reproducer itself (MTR `.test`/`.result`, `.yy` grammar + runner script,
  or harness scripts) with everything needed to re-run it;
* any harness scripts used, so the next person does not have to rebuild them.

State plainly what was verified and what was not.
