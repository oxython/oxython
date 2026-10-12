#!/usr/bin/env bash
# Apply the oxython patch series to the upstream Cython checkout and copy in
# the oxython tests.
#
#   scripts/apply.sh            # use ./upstream at the pinned commit
#   UPSTREAM_REF=master scripts/apply.sh   # try the series on another upstream ref
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
up="$root/upstream"
branch="${OXYTHON_BRANCH:-oxython}"

if [ ! -e "$up/.git" ]; then
    git -C "$root" submodule update --init upstream
fi

base="${UPSTREAM_REF:-$(git -C "$root" ls-files -s upstream | awk '{print $2}')}"
if [ -n "${UPSTREAM_REF:-}" ]; then
    git -C "$up" fetch --quiet origin "$UPSTREAM_REF"
    base="$(git -C "$up" rev-parse FETCH_HEAD)"
fi

git -C "$up" checkout --quiet -B "$branch" "$base"

export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-oxython}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-oxython@localhost}"
while IFS= read -r patch; do
    case "$patch" in ''|'#'*) continue ;; esac
    echo "applying $patch"
    if ! git -C "$up" am --quiet --3way "$root/patches/$patch"; then
        echo "error: $patch does not apply to $(git -C "$up" rev-parse --short "$base")" >&2
        git -C "$up" am --abort || true
        exit 1
    fi
done < "$root/patches/series"

"$root/scripts/copy-tests.sh"
echo "oxython applied on top of upstream $(git -C "$up" rev-parse --short "$base")"
