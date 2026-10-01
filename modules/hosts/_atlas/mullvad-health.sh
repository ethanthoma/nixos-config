#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq tailscale coreutils
set -euo pipefail

socket=/run/tailscale-mullvad/tailscaled.sock

check_connection() {
  local response
  response=$(curl --interface mullvad0 --connect-timeout 4 --max-time 8 --fail --silent --show-error \
    https://am.i.mullvad.net/json) || return 1
  jq --exit-status '.mullvad_exit_ip == true' <<<"$response" >/dev/null
}

for _attempt in 1 2 3; do
  if check_connection; then
    exit 0
  fi
  sleep 3
done

current=$(tailscale --socket="$socket" debug prefs | jq --exit-status --raw-output '.ExitNodeID | select(length > 0)')
peers=$(tailscale --socket="$socket" status --json)
current_address=$(jq --exit-status --raw-output --arg current "$current" \
  '.Peer[] | select(.ID == $current) | .TailscaleIPs[0]' <<<"$peers")
case "$current_address" in
"$EXIT_FIRST") target=$EXIT_SECOND ;;
"$EXIT_SECOND") target=$EXIT_FIRST ;;
*)
  echo "Mullvad: selected exit is outside the recovery pair; leaving it unchanged" >&2
  exit 1
  ;;
esac
jq --exit-status --arg target "$target" \
  'any(.Peer[]; .TailscaleIPs[0] == $target and .Online == true and (.Tags | index("tag:mullvad-exit-node") != null))' \
  <<<"$peers" >/dev/null
echo "Mullvad: three failed checks; switching from $current_address to $target"
tailscale --socket="$socket" set --exit-node="$target"
sleep 5
if ! check_connection; then
  echo "Mullvad: replacement exit is still unhealthy; traffic remains restricted to Mullvad" >&2
  exit 1
fi
