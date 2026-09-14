#!/bin/sh
set -eu

package_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/autoscribe-dispatch-filter-test.XXXXXX")
case "$test_dir" in
  "${TMPDIR:-/tmp}"/autoscribe-dispatch-filter-test.*) ;;
  *) echo "unsafe temporary test directory: $test_dir" >&2; exit 1 ;;
esac
trap 'rm -rf -- "$test_dir"' EXIT HUP INT TERM

document="$test_dir/worktree/Content/source.md"
runtime="$test_dir/runtime.yaml"
mkdir -p "$(dirname -- "$document")"
cat > "$document" <<'EOF'
---
slug: cnt.filter-test
title: Filter Test
status: draft
plan: plan.from-document
---

::: directive
Use concise language.
:::

Fixture body.
EOF
cat > "$runtime" <<EOF
input-files:
  - "$document"
metadata:
  plan: plan.from-runtime
EOF

output=$(
  cd "$package_dir"
  /usr/bin/pandoc \
    --defaults="$package_dir/defaults/dispatch.yaml" \
    --defaults="$runtime"
)
python3 -c '
import json, sys
record = json.loads(sys.stdin.read())
assert record["type"] == "call"
assert record["identity"] == "cnt.filter-test"
assert record["content"] == "Fixture body."
assert record["directive"] == "Use concise language."
assert record["plan"] == "plan.from-runtime"
assert record["extra"]["filename_hint"] == "source.md"
assert record["extra"]["source_path"] == "Content/source.md"
assert record["extra"]["metadata"] == {
    "slug": "cnt.filter-test",
    "status": "draft",
    "title": "Filter Test",
}
' <<EOF
$output
EOF

cat > "$runtime" <<EOF
input-files:
  - "$test_dir/missing-plan.md"
EOF
cat > "$test_dir/missing-plan.md" <<'EOF'
---
slug: cnt.missing-plan
---

Body.
EOF
if (
  cd "$package_dir"
  /usr/bin/pandoc \
    --defaults="$package_dir/defaults/dispatch.yaml" \
    --defaults="$runtime" > "$test_dir/missing-plan.stdout" 2> "$test_dir/missing-plan.stderr"
); then
  echo "dispatch filter accepted missing plan metadata" >&2
  exit 1
fi
grep -q "plan metadata is missing" "$test_dir/missing-plan.stderr"

cat > "$test_dir/missing-slug.md" <<'EOF'
Body without frontmatter.
EOF
cat > "$runtime" <<EOF
input-files:
  - "$test_dir/missing-slug.md"
metadata:
  plan: plan.from-runtime
EOF
if (
  cd "$package_dir"
  /usr/bin/pandoc \
    --defaults="$package_dir/defaults/dispatch.yaml" \
    --defaults="$runtime" > "$test_dir/missing-slug.stdout" 2> "$test_dir/missing-slug.stderr"
); then
  echo "dispatch filter accepted a document without a slug" >&2
  exit 1
fi
grep -q "document slug is missing" "$test_dir/missing-slug.stderr"

printf '%s\n' "dispatch_calls filter tests passed"
