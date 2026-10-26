#!/usr/bin/env bash
# Upload images from static/media/ to Cloudflare R2.
#
# Default: upload only local files whose names are not yet on R2.
# --derivatives: also create NAME-1200.jpg for each master (long side 1200px)
#                that lacks one, and include them in the upload.
# --dry-run:     print what would be created or uploaded, change nothing.
#
# Usage:
#   ./upload-images.sh               # new masters only
#   ./upload-images.sh --dry-run     # preview
#   ./upload-images.sh --derivatives # new masters + 1200px copies

set -euo pipefail

REMOTE="r2:aadm-images/media/"
LOCAL_DIR="static/media"
DERIV_SIZE="1200x1200>"
DERIV_QUALITY=85

derivatives=0
dry_run=0

for arg in "$@"; do
  case "$arg" in
    --derivatives) derivatives=1 ;;
    --dry-run) dry_run=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

cd "$(dirname "$0")"

if [ "$derivatives" -eq 1 ]; then
  while IFS= read -r -d '' src; do
    name=$(basename "$src")
    case "$name" in
      *-1200.jpg) continue ;;
    esac
    dst="${src%.*}-1200.jpg"
    if [ ! -e "$dst" ] || [ "$src" -nt "$dst" ]; then
      if [ "$dry_run" -eq 1 ]; then
        echo "would create: $dst"
      else
        echo "creating: $dst"
        magick "$src" -auto-orient -strip -resize "$DERIV_SIZE" \
          -quality "$DERIV_QUALITY" "$dst"
      fi
    fi
  done < <(find "$LOCAL_DIR" -maxdepth 1 -type f -iname '*.jpg' -print0)
fi

remote_list=$(mktemp)
local_list=$(mktemp)
trap 'rm -f "$remote_list" "$local_list"' EXIT

rclone lsf "$REMOTE" | sort -u > "$remote_list"
(cd "$LOCAL_DIR" && find . -maxdepth 1 -type f -iname '*.jpg' -printf '%f\n' | sort -u) \
  > "$local_list"

to_upload=$(comm -23 "$local_list" "$remote_list")

if [ -z "$to_upload" ]; then
  echo "Nothing new to upload."
  exit 0
fi

count=$(printf '%s\n' "$to_upload" | wc -l)
echo "$count file(s) not on R2:"
printf '%s\n' "$to_upload" | sed 's/^/  /'

if [ "$dry_run" -eq 1 ]; then
  echo "Dry run: nothing uploaded."
  exit 0
fi

files_from=$(mktemp)
printf '%s\n' "$to_upload" > "$files_from"
trap 'rm -f "$remote_list" "$local_list" "$files_from"' EXIT

rclone copy "$LOCAL_DIR" "$REMOTE" --files-from "$files_from" -P
echo "Done."
