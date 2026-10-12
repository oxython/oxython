#!/usr/bin/env bash
# Build the 'oxython' sdist and wheel into dist/.
#
# The distribution is the patched Cython under the name 'oxython'.  It
# still installs the 'Cython' package, so it replaces Cython in the
# environment it is installed into.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
version="$(cat "$root/VERSION")"

"$root/scripts/apply.sh" >/dev/null

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
git -C "$root/upstream" archive HEAD | tar -x -C "$build"
cp "$root/README.md" "$build/OXYTHON_README.md"

python3 - "$build/setup.py" "$version" <<'PY'
import re, sys
path, version = sys.argv[1], sys.argv[2]
s = open(path).read()
start = s.index("    setup(\n        name='Cython',")
end = s.index("        license='Apache-2.0',", start)
s = s[:start] + f'''    setup(
        name='oxython',
        version={version!r},
        url='https://github.com/oxython/oxython',
        author='Rin Arakaki',
        description="Cython with a Rust-flavoured syntax in .oxy files.",
        long_description_content_type="text/markdown",
        long_description=open("OXYTHON_README.md", encoding="utf-8").read(),
''' + s[end:]
s = re.sub(r'        project_urls=\{.*?\n        \},\n',
           '''        project_urls={
            "Source Code": "https://github.com/oxython/oxython",
            "Bug Tracker": "https://github.com/oxython/oxython/issues",
            "Upstream": "https://github.com/cython/cython",
        },
''', s, count=1, flags=re.S)
s = s.replace("            dev_status(version),\n", "            \"Development Status :: 3 - Alpha\",\n", 1)
open(path, "w").write(s)
PY
echo "include OXYTHON_README.md" >> "$build/MANIFEST.in"

rm -rf "$root/dist"
( cd "$build" && NO_CYTHON_COMPILE=true python3 -m build --outdir "$root/dist" . )
ls -1 "$root/dist"
