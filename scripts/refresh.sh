#!/usr/bin/env bash
# Regenerate patches/ from the commits on the upstream work branch.
# Each commit on top of the pinned upstream commit becomes one patch.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
up="$root/upstream"
base="$(git -C "$root" ls-files -s upstream | awk '{print $2}')"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -C "$up" format-patch --quiet --no-numbered --no-signature --zero-commit --no-stat \
    -o "$tmp" "$base..HEAD"

rm -f "$root"/patches/*.patch
# keep patch file names lowercase
for f in "$tmp"/*.patch; do
    cp "$f" "$root/patches/$(basename "$f" | tr '[:upper:]' '[:lower:]')"
done
( cd "$root/patches" && ls -1 *.patch ) > "$root/patches/series"
echo "wrote $(wc -l < "$root/patches/series") patches"
