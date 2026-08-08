#!/bin/bash
# Start a mariadbd in this sandbox and run a driver script against it. Clients
# connect over the unix socket (unix sockets work here; TCP would not survive a
# change of Bash invocation, the socket does).
#
#   start-server.sh <driver.sh> [extra mariadbd options...]
#
# The driver is sourced with these available:
#   Q "<sql>"          run SQL, print the result
#   BLD, DD, PORT, SOCK  build dir, work dir, port, socket path
#   errlog             path to the server error log
#
# The server is backgrounded with plain `&`, so it dies with this Bash tool
# invocation: server and clients must live in the SAME invocation. To keep a
# server across invocations, start mariadbd yourself with run_in_background and
# connect later with --socket=$SOCK (a background server IS reachable that way;
# TCP and PIDs are not, since each invocation gets its own network and PID
# namespace — shut it down with `mariadb-admin --socket=$SOCK -uroot shutdown`).
#
# Keep DD short: a socket path over 107 characters is rejected by the server, so
# do NOT point DD at the session scratchpad.
#
# Env:
#   BLD    build directory            (default /data/bld/bb-main-atomic-rel)
#   DD     work directory             (default /data/local/rqg-srv)
#   PORT   TCP port                   (default 14567)
#   SRC    datadir to copy and use    (default: bootstrap a fresh one)
#   USER   connect as                 (default root)
set -u
BLD=${BLD:-/data/bld/bb-main-atomic-rel}
DD=${DD:-/data/local/rqg-srv}
PORT=${PORT:-14567}
USER=${USER:-root}
SOCK=${SOCK:-$DD/my.sock}
DRIVER=${1:-}
[ -n "$DRIVER" ] && shift

rm -rf "$DD"; mkdir -p "$DD/tmp"
if [ -n "${SRC:-}" ]; then
  cp -a "$SRC/data" "$DD/data"
  [ -d "$SRC/tmp" ] && cp -a "$SRC/tmp/." "$DD/tmp/" 2>/dev/null
else
  ( cd "$BLD" && ./scripts/mariadb-install-db --no-defaults \
      --srcdir="${SRCDIR:-/data/src/bb-main-atomic}" --datadir="$DD/data" ) >/dev/null 2>&1
fi

errlog=$DD/err.log
"$BLD/sql/mariadbd" --no-defaults --basedir="$BLD" --lc-messages-dir="$BLD/sql/share" \
  --datadir="$DD/data" --tmpdir="$DD/tmp" --port=$PORT --socket="$SOCK" \
  --log-error="$errlog" --pid-file="$DD/mysql.pid" \
  --plugin-maturity=experimental "$@" >/dev/null 2>&1 &
SRVPID=$!

# Poll with the client, not with the log: the log line can appear before the
# listener is usable, and a single connect attempt is fragile.
up=0
for i in $(seq 1 120); do
  if "$BLD/client/mariadb" --socket="$SOCK" -u"$USER" \
       --connect-timeout=1 -e "select 1" >/dev/null 2>&1; then up=1; break; fi
  python3 -c "import time;time.sleep(0.5)"
done
if [ $up = 0 ]; then
  echo "server failed to start; tail of $errlog:" >&2
  tail -20 "$errlog" >&2
  kill $SRVPID 2>/dev/null
  exit 1
fi
echo "server up: socket $SOCK, port $PORT, datadir $DD/data, errlog $errlog"

Q() { "$BLD/client/mariadb" --socket="$SOCK" -u"$USER" -t --force \
        -D "${DB:-test}" -e "$1" 2>&1 | grep -v ssl-verify-server-cert; }
export -f Q 2>/dev/null || true

if [ -n "$DRIVER" ]; then
  # shellcheck disable=SC1090
  source "$DRIVER"
fi

# Only ever wait on client PIDs; a bare `wait` would block on the server forever.
kill $SRVPID 2>/dev/null; wait $SRVPID 2>/dev/null
