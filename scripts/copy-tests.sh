#!/usr/bin/env bash
# Copy the oxython tests into the upstream test tree, where runtests.py finds them.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
for kind in run errors compile; do
    rm -rf "$root/upstream/tests/$kind"/oxython_*
    [ -d "$root/tests/$kind" ] || continue
    for f in "$root/tests/$kind"/*; do
        [ -e "$f" ] || continue
        cp -R "$f" "$root/upstream/tests/$kind/"
    done
done
