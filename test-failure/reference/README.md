Reference material for the `test-failure` skill.

| file | status |
|---|---|
| `rqg-no-unix-socket.patch` | **Obsolete in the current sandbox configuration.** Unix sockets are permitted (`sandbox.network.allowAllUnixSockets: true`), so stock RQG runs unmodified. Keep only in case the AF_UNIX seccomp block is reinstated — see *If AF_UNIX is blocked again* in `../SKILL.md`. |
