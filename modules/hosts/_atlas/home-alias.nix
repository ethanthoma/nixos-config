# The Surface laptop's user lives at /home/ethanthoma; here the same person is
# ethoma at /home/ethoma. The alias lets paths recorded on the laptop (Claude Code
# sessions, working directories, scripts) resolve on Atlas. "L" never replaces an
# existing path.
{
  systemd.tmpfiles.rules = [
    "L /home/ethanthoma - - - - /home/ethoma"
  ];
}
