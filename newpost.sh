#!/usr/bin/env bash
set -euo pipefail

slug="${1:?Usage: newpost <slug> [en|it]}"
lang="${2:-en}"
today="$(date +%Y-%m-%d)"
now="$(date +%Y-%m-%dT%H:%M:%S%z)"
path="content/post/${today}-${slug}.${lang}.md"

# derive title from slug: replace '-' with ' ', capitalize each word
t="${slug//-/ }"
title=""
for w in $t; do
  title+="${w^} "
done
title="${title% }"

if [ -f "$path" ]; then
  echo "Error: $path already exists" >&2
  exit 1
fi

cat > "$path" <<EOF
---
title: $title
date: '$now'
draft: true
author: aadm
tags:
---

EOF

echo "Created: $path"
