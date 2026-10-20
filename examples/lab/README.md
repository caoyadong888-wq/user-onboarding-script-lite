# Lite lab

Set `ONBOARD_ROOT` to this directory. It is a fake root, not the host.

- `etc/passwd` has `root` and `ops` (uid 1000)
- `etc/group` has `sudo` (gid 27) with `ops` already a member
- `etc/shadow` keeps both passwords locked
- `etc/skel/README.txt` is copied into a new home

`onboard-lite.sh` creates one account, optionally adds `sudo`, and installs a public key. It refuses `--live` and `--force-delete`. Expiry, CSV batch, archive, and offboarding are in the full pack.
