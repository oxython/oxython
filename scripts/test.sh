#!/usr/bin/env bash
# Run the oxython tests (and any extra runtests.py arguments) against the
# patched upstream tree.  Run scripts/apply.sh first.
#
#   scripts/test.sh              # all oxython tests
#   scripts/test.sh -j4 memslice # oxython tests plus an upstream test
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
"$root/scripts/copy-tests.sh"
cd "$root/upstream"
exec python runtests.py --no-pyregr --no-cpp-locals -j"${JOBS:-4}" "$@" oxython_
