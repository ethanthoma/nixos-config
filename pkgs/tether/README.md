# tether

Single-user comms hub: syncs Gmail (IMAP) + Google Calendar (secret ICS URL)
into a JSON state dir on atlas, triages threads with the local llama-server,
extracts commitments, and reaches you through ntfy nudges, a morning Discord
digest, and an on-demand CLI.

```
tether sync                        fetch new mail + calendar
tether triage                      LLM-classify new threads, extract commitments
tether nudge                       evaluate nudge rules, push via ntfy
tether digest                      post morning digest to Discord + ntfy ping
tether pulse                       sync + triage + nudge (what the timer runs)
tether ask "who am I ghosting?"    question over the store
tether list [threads|commitments|contacts|reminders]
tether done <id>                   close thread / keep commitment / finish reminder
tether snooze <id> 3d
tether track alice@example.com 30
tether remind "renew passport" 2026-09-01
```

## Configuration (environment)

| var | meaning |
|---|---|
| `TETHER_STATE_DIR` | state dir, default `/var/lib/tether` |
| `TETHER_IMAP_USER` | Gmail address |
| `TETHER_IMAP_PASSWORD` | Gmail app password (myaccount.google.com/apppasswords, needs 2FA) |
| `TETHER_MY_EMAIL` | defaults to `TETHER_IMAP_USER` |
| `TETHER_ICS_URL` | Calendar settings → "Secret address in iCal format" |
| `TETHER_NTFY_TOPIC` | ntfy topic name, or full URL for self-hosted ntfy |
| `TETHER_DISCORD_WEBHOOK` | webhook URL of a private channel |
| `TETHER_LLM_URL` | default `http://127.0.0.1:8080` |
| `LLAMA_API_KEY` | same value as in `/var/lib/llama-server.env` on atlas |

Secrets are declared in `secretspec.toml` (keyring provider, KeePassXC via
Secret Service, same setup as the website repo). `secretspec check` populates
missing entries, then `make provision` renders `/var/lib/tether.env` on atlas
(owned `ethoma`, mode 600), pulling `LLAMA_API_KEY` from
`/var/lib/llama-server.env` there. The packaged `tether` command sources that
file, so timers and `ssh atlas tether ask` behave identically. The timers stay
dormant until the file exists.

## Deploy

`make deploy` rsyncs the source to `atlas:/etc/nixos/tether/`; atlas's
configuration.nix builds it with `pkgs.buildGoModule { vendorHash = null; }`
and runs `tether-pulse.timer` (every 15 min) and `tether-digest.timer` (07:00),
both with `EnvironmentFile=/var/lib/tether.env`.

## Dev

`make build`, `make test`. Local runs: `TETHER_STATE_DIR=/tmp/tether-dev ./tether sync`.
On this machine, prefix with `nix-shell -p go --run '...'`.
