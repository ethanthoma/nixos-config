# Atlas account migration

## Status

Configuration prepared and built; live account migration has not run. Atlas still uses `ethoma`, UID 1001.
Do not activate the new Atlas configuration before completing the offline account and home migration below.
A normal NixOS switch is not an account rename and may leave conflicting account records.

Target: one normal login account named `ethanthoma`, UID 1001, home `/home/ethanthoma`, with the existing SSH keys.
No permanent old-home alias is intended.

## Preflight evidence

- `/home/ethanthoma` is currently a root-owned symlink to `/home/ethoma`, not another account.
- `/etc/nixos` on Atlas was clean at `4a0137c` before migration preparation.
- The desktop checkout contains the prepared configuration; it has not been copied to Atlas.
- Atlas has approximately 32 GiB free. Do not duplicate the entire home: `.local/state` alone is 75 GiB.
- Training queue is inactive; unfinished Pueue jobs are stashed. Preserve group pause states and queued task paths.
- Synth continuous production, Synth operations, Synth NATS, Relay workers, and SSH/tmux are active.
- The user authorized stopping/restarting Synth and Relay and disconnecting the existing Atlas sessions.
- User units, Synth manifests, Codex databases, Pi session metadata, and absolute symlinks contain old home paths.
- SSH client aliases `sockeye.arc.ubc.ca` and `nibi` also use `ethoma`; do not change those unrelated identities.

## Remaining execution gates

1. Verify the prepared closure and inspect the deployed-to-target diff. Copy the closure without changing the running system.
2. Inventory active system/user services and processes; save their state, old system closure, account/group/shadow records,
   authorized-key fingerprints, host-key fingerprints, and old linger configuration in a root-only rollback directory.
3. Prepare a root-owned migration job and a tested rollback path independent of the renamed login. Include a timed rollback
   unless a fresh authenticated connection explicitly acknowledges success. Do not rely on the old SSH shell surviving.
4. Stop authorized writers and account processes. Codex uses process-only kill behavior: check entire service cgroups for
   remaining writers. Verify Pueue is idle and stop its daemon without changing paused/stashed task state.
5. Back up the mutable files that will change. Use SQLite's backup interface after writers stop, verify integrity, and record
   checksums. Keep credentials and backups private. Preserve unrelated project edits and immutable historical artifacts.
6. Remove only the verified `/home/ethanthoma -> /home/ethoma` symlink. Rename the account while preserving UID 1001,
   move the home on the same filesystem, set its new home, and migrate linger state. Do not create another UID.
7. Repair active user units, project/service manifests, queued working directories, absolute symlinks, agent configuration,
   database path columns, and session discovery metadata. Inventory references outside the home as well. Do not blindly
   replace bytes in binary files, databases, credentials, or historical logs.
8. Activate the prepared system and restore the previously active services. Verify Home Manager and all service errors.
9. From a separate connection, authenticate as `ethanthoma` with the existing key, verify UID/home/groups/sudo and unchanged
   server host keys, and confirm that `ethoma` no longer resolves. Then update only the desktop's `Host atlas` SSH user.
10. Verify hosted applications, Synth, Relay, Pueue state, agent session counts/database integrity, and remaining active old-path
    references. Acknowledge the rollback timer only after these checks pass. Retain private rollback backups.

## Rollback requirements

Keep the old system closure rooted and preserve original account records and every edited mutable file/database. With
writers stopped, restore these records, reverse the same-filesystem home move, restore the original home symlink and
linger entry, reactivate the old system, and restart the recorded services. Verify old-user SSH access before declaring
rollback successful. Restore the desktop SSH alias if it was changed.
