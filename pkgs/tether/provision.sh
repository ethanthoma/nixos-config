#!/usr/bin/env bash
set -euo pipefail

for var in TETHER_IMAP_USER TETHER_IMAP_PASSWORD TETHER_ICS_URL TETHER_NTFY_TOPIC TETHER_DISCORD_WEBHOOK; do
  if [ -z "${!var:-}" ]; then
    echo "missing $var - run via: secretspec run -- ./provision.sh" >&2
    exit 1
  fi
done

llama_key_line=$(ssh atlas sudo grep '^LLAMA_API_KEY=' /var/lib/llama-server.env)

{
  printf "TETHER_IMAP_USER='%s'\n" "$TETHER_IMAP_USER"
  printf "TETHER_IMAP_PASSWORD='%s'\n" "$TETHER_IMAP_PASSWORD"
  printf "TETHER_ICS_URL='%s'\n" "$TETHER_ICS_URL"
  printf "TETHER_NTFY_TOPIC='%s'\n" "$TETHER_NTFY_TOPIC"
  printf "TETHER_DISCORD_WEBHOOK='%s'\n" "$TETHER_DISCORD_WEBHOOK"
  printf '%s\n' "$llama_key_line"
} | ssh atlas "sudo install -m 600 -o ethoma -g users /dev/stdin /var/lib/tether.env"

echo "provisioned /var/lib/tether.env on atlas; next pulse activates tether"
