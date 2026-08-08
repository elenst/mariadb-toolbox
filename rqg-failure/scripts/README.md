Helper scripts bundled with the `rqg-failure` skill.

| script | purpose |
|---|---|
| `start-server.sh` | Start a `mariadbd` with a unix socket, poll it with the client, then source a driver script. Encodes the pitfalls: short work dir (107-char socket limit), server and clients in the same Bash invocation, client-based polling, never a bare `wait`. |
| `split_genlog.pl` | Split an RQG general query log into one replayable `.sql` per connection for a time window — the basis of "replay the recorded streams" reproduction. |

Typical use:

```sh
# 1. recover the per-connection statement streams from the trial
perl split_genlog.pl <vardir>/s1/mysql.log /data/local/replay 17:03:30 17:04:51

# 2. drive a server with them, or with a matrix of hand-written cases
SRC=<vardir>/s1 DD=/data/local/run PORT=14590 ./start-server.sh driver.sh --log-bin
```

where `driver.sh` uses the `Q "<sql>"` helper that `start-server.sh` exports, or
launches its own clients — collecting their PIDs and waiting only on those.
