#!/usr/bin/env python3
"""Convert Pelican markdown posts to Hugo format."""

import os
import re
import yaml
from datetime import datetime
from pathlib import Path

OLD_CONTENT = Path("/home/aadm/Documents/blog/content")
NEW_CONTENT = Path("/home/aadm/Documents/aadm-hugo/content/post")

# fields to skip in Hugo frontmatter
SKIP_FIELDS = {"status", "related_posts", "lang", "category"}

def parse_pelican_post(text):
    """Parse Pelican frontmatter and content."""
    lines = text.split("\n")
    frontmatter = {}
    body_start = 0

    # parse header fields (Title:, Date:, Tags:, etc.)
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip() == "":
            body_start = i + 1
            break
        match = re.match(r'^(\w[\w\s]*?):\s*(.*)', line)
        if match:
            key = match.group(1).strip()
            value = match.group(2).strip()
            frontmatter[key] = value
        i += 1

    body = "\n".join(lines[body_start:]).strip()
    return frontmatter, body


def parse_date(date_str):
    """Parse Pelican date formats into Hugo-compatible ISO format."""
    if not date_str:
        return None
    date_str = date_str.strip()
    # try various formats
    formats = [
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%d %H:%M",
        "%Y-%m-%d",
        "%Y/%m/%d",
    ]
    for fmt in formats:
        try:
            dt = datetime.strptime(date_str, fmt)
            if fmt == "%Y-%m-%d":
                return dt.strftime("%Y-%m-%d")
            return dt.strftime("%Y-%m-%dT%H:%M:%S")
        except ValueError:
            continue
    # if all fail, return as-is (might still break)
    return date_str


def convert_tags(tags_str):
    """Convert Pelican tags string to Hugo list."""
    if not tags_str:
        return []
    return [t.strip() for t in tags_str.split(",")]


def convert_post(src_path, is_page=False):
    """Convert a single Pelican post to Hugo format."""
    text = src_path.read_text(encoding="utf-8")
    frontmatter, body = parse_pelican_post(text)

    # determine language
    lang = frontmatter.pop("Lang", None)
    if lang and lang.strip() == "en":
        lang = "en"
    else:
        lang = None  # Italian / default

    # status -> draft
    status = frontmatter.pop("Status", None)
    draft = False
    status_raw = frontmatter.pop("status", None)
    if (status and status.strip().lower() == "draft") or \
       (status_raw and status_raw.strip().lower() == "draft"):
        draft = True

    # build Hugo frontmatter
    hugo_fm = {}
    for key, value in frontmatter.items():
        key_lower = key.lower()
        if key_lower in SKIP_FIELDS:
            continue
        # map Pelican keys to Hugo keys
        if key_lower == "title":
            hugo_fm["title"] = value
        elif key_lower == "date":
            parsed = parse_date(value)
            if parsed:
                hugo_fm["date"] = parsed
        elif key_lower == "tags":
            hugo_fm["tags"] = convert_tags(value)
        elif key_lower == "slug":
            hugo_fm["slug"] = value
        elif key_lower == "author":
            pass  # skip, we set globally
        else:
            hugo_fm[key_lower] = value

    if draft:
        hugo_fm["draft"] = True

    # build output filename
    src_name = src_path.stem  # e.g. "2019-04-30-moto-guzzi-v7"
    if lang == "en":
        out_name = f"{src_name}.en.md"
    else:
        out_name = f"{src_name}.md"

    # pages go to content/ root, posts go to content/post/
    if is_page:
        out_dir = NEW_CONTENT.parent  # content/
    else:
        out_dir = NEW_CONTENT  # content/post/

    out_path = out_dir / out_name
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("---\n")
        yaml.dump(hugo_fm, f, allow_unicode=True, default_flow_style=False, sort_keys=False)
        f.write("---\n\n")
        f.write(body)

    return out_path.name


def main():
    NEW_CONTENT.mkdir(parents=True, exist_ok=True)

    # convert blog posts
    posts = sorted(OLD_CONTENT.glob("*.md"))
    converted = 0
    drafts = 0
    for src in posts:
        name = convert_post(src)
        status = "draft" if "draft" in name else "ok"
        print(f"  {status:5s}  {name}")
        converted += 1
        if status == "draft":
            drafts += 1

    # convert pages (about, projects, etc.)
    pages_dir = OLD_CONTENT / "pages"
    for src in sorted(pages_dir.glob("*.md")):
        # skip 404 page
        if src.stem == "404":
            continue
        name = convert_post(src, is_page=True)
        print(f"  page  {name}")

    print(f"\nDone. {converted} posts converted ({drafts} drafts).")


if __name__ == "__main__":
    main()
