#!/bin/bash
# move_and_link.sh SRC DST
# Moves SRC to DST, creates symlink at SRC pointing to DST, verifies.
set -euo pipefail
SRC="$1"
DST="$2"

[ -e "$DST" ] && { echo "FAIL: dst exists: $DST"; exit 1; }
[ ! -e "$SRC" ] && { echo "FAIL: src missing: $SRC"; exit 1; }
[ -L "$SRC" ] && { echo "SKIP: src already a symlink: $SRC"; exit 0; }

mkdir -p "$(dirname "$DST")"
mv "$SRC" "$DST"
ln -s "$DST" "$SRC"

# Verify
[ "$(readlink "$SRC")" = "$DST" ] || { echo "FAIL: readlink mismatch"; exit 1; }
[ -e "$SRC" ] || { echo "FAIL: symlink broken"; exit 1; }
echo "OK $SRC -> $DST"
