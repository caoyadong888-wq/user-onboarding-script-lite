#!/usr/bin/env bash
# Lite onboard: one user, optional sudo, optional public key, lab root only.
# No CSV, no expiry, no offboarding, no --live. The full pack adds those.
set -euo pipefail

DRY_RUN=0
DO_SUDO=0
TARGET_USER=""
GECOS=""
KEYFILE=""
LOGIN_SHELL="/bin/bash"

die() {
  printf 'ERROR %s\n' "$*" >&2
  exit "${1:-2}"
}

usage() {
  cat <<'EOF'
Usage: onboard-lite.sh --user NAME [--sudo] [--keys FILE] [--fullname TEXT] [--dry-run]

Requires ONBOARD_ROOT (a directory with etc/passwd, etc/group, etc/shadow, etc/skel, home/).
Refuses --live and --force-delete. Those are in the full pack.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      [[ $# -ge 2 ]] || die 2 "missing value for --user"
      TARGET_USER="$2"
      shift 2
      ;;
    --fullname)
      [[ $# -ge 2 ]] || die 2 "missing value for --fullname"
      GECOS="$2"
      shift 2
      ;;
    --keys)
      [[ $# -ge 2 ]] || die 2 "missing value for --keys"
      KEYFILE="$2"
      shift 2
      ;;
    --shell)
      [[ $# -ge 2 ]] || die 2 "missing value for --shell"
      LOGIN_SHELL="$2"
      shift 2
      ;;
    --sudo) DO_SUDO=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --live) die 4 "lite build refuses --live; use the full pack" ;;
    --force-delete) die 4 "lite build has no offboard; use the full pack" ;;
    -h|--help) usage; exit 0 ;;
    *) die 2 "unknown argument: $1" ;;
  esac
done

[[ -n "$TARGET_USER" ]] || die 2 "pass --user"
[[ "$TARGET_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || die 2 "invalid username: ${TARGET_USER}"
[[ "$TARGET_USER" != "root" ]] || die 4 "refusing to manage root"
[[ -n "${ONBOARD_ROOT:-}" ]] || die 4 "set ONBOARD_ROOT to a lab tree"
ROOT="${ONBOARD_ROOT%/}"
[[ "$ROOT" != "/" && -d "$ROOT" ]] || die 4 "ONBOARD_ROOT cannot be /"
[[ -z "$GECOS" ]] && GECOS="$TARGET_USER"

passwd="${ROOT}/etc/passwd"
group="${ROOT}/etc/group"
shadow="${ROOT}/etc/shadow"
skel="${ROOT}/etc/skel"
[[ -f "$passwd" && -f "$group" && -f "$shadow" && -d "$skel" ]] || die 4 "lab tree is missing etc files"

if [[ "$DRY_RUN" == "1" ]]; then
  printf 'MODE dry-run\n'
else
  printf 'MODE apply\n'
fi
printf 'ROOT %s\n' "$ROOT"

if awk -F: -v u="$TARGET_USER" '$1==u { found=1 } END { exit !found }' "$passwd"; then
  printf 'ERROR user already exists: %s\n' "$TARGET_USER" >&2
  exit 2
fi

uid="$(awk -F: 'BEGIN { m = 999 } $3 ~ /^[0-9]+$/ && ($3+0) > m { m = $3+0 } END { print m+1 }' "$passwd" "$group")"
printf 'ACTION create_user user=%s uid=%s gid=%s shell=%s home=/home/%s gecos="%s"\n' \
  "$TARGET_USER" "$uid" "$uid" "$LOGIN_SHELL" "$TARGET_USER" "$GECOS"
printf 'ACTION create_primary_group user=%s gid=%s\n' "$TARGET_USER" "$uid"
if [[ "$DO_SUDO" == "1" ]]; then
  printf 'ACTION add_group user=%s group=sudo status=add\n' "$TARGET_USER"
fi
printf 'ACTION copy_skel user=%s src=/etc/skel dest=/home/%s\n' "$TARGET_USER" "$TARGET_USER"
if [[ -n "$KEYFILE" ]]; then
  [[ -f "$KEYFILE" ]] || die 2 "keys file not found: ${KEYFILE}"
  if grep -q -F "PRIVATE KEY" "$KEYFILE"; then
    die 2 "refusing private key material: ${KEYFILE}"
  fi
  printf 'ACTION install_authorized_keys user=%s src=%s dest=/home/%s/.ssh/authorized_keys mode=0600\n' \
    "$TARGET_USER" "$KEYFILE" "$TARGET_USER"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  printf 'RESULT user=%s status=planned\n' "$TARGET_USER"
  exit 0
fi

printf '%s:x:%s:%s:%s:/home/%s:%s\n' \
  "$TARGET_USER" "$uid" "$uid" "$GECOS" "$TARGET_USER" "$LOGIN_SHELL" >>"$passwd"
printf '%s:x:%s:\n' "$TARGET_USER" "$uid" >>"$group"
if [[ "$DO_SUDO" == "1" ]]; then
  if awk -F: '$1=="sudo" { found=1 } END { exit !found }' "$group"; then
    awk -F: -v u="$TARGET_USER" 'BEGIN { OFS=":" } $1=="sudo" { if ($4=="") $4=u; else $4=$4 "," u } { print }' \
      "$group" >"${group}.tmp"
    mv -f "${group}.tmp" "$group"
  else
    printf 'sudo:x:27:%s\n' "$TARGET_USER" >>"$group"
  fi
fi
lastchg="$(( $(date -u +%s) / 86400 ))"
printf '%s:!%s:%s:0:99999:7:::\n' "$TARGET_USER" "" "$lastchg" >>"$shadow"

home="${ROOT}/home/${TARGET_USER}"
mkdir -p "$home"
shopt -s dotglob nullglob
for item in "$skel"/*; do
  base="$(basename -- "$item")"
  [[ -e "$home/$base" ]] && continue
  cp -a -- "$item" "$home/$base"
done
shopt -u dotglob nullglob
chmod 755 "$home"
if [[ -n "$KEYFILE" ]]; then
  mkdir -p "$home/.ssh"
  cat -- "$KEYFILE" >"$home/.ssh/authorized_keys"
  chmod 700 "$home/.ssh"
  chmod 600 "$home/.ssh/authorized_keys"
fi
printf 'RESULT user=%s status=applied\n' "$TARGET_USER"
