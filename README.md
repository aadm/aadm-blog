# aadm-blog

Hugo-based personal blog, migrated from Pelican. Deployed on Cloudflare Pages with Cloudflare R2 for images.

## Quick reference

### Full workflow: new post with images

```bash
# 1. create post (as draft)
./newpost.sh my-new-post en

# 2. drop images in static/media/
cp /path/to/photos/*.jpg static/media/

# 3. write the post, add figure shortcodes
# edit content/post/YYYY-MM-DD-my-new-post.en.md

# 4. preview locally
hugo server --buildDrafts

# 5. when done, upload new images to R2 (only files not already on R2)
./upload-images.sh

# 6. remove local copies (they're gitignored but save disk space)
rm static/media/my-*.jpg

# 7. publish: remove draft: true from frontmatter, commit, push
git add -A && git commit -m "New post: my-new-post" && git push
```

### Create a new post

```bash
./newpost.sh my-post-slug en     # English
./newpost.sh mio-post it         # Italian
```

Creates `content/post/YYYY-MM-DD-my-post-slug.en.md` with `draft: true` in frontmatter.
Posts are stored in `content/post/` — drafts and published posts live together,
differentiated only by the `draft` field.

### Preview drafts

```bash
hugo server --buildDrafts         # includes drafts
hugo server                       # published only
```

Serves at `http://localhost:1313/`. Development config (`config/development/params.yaml`)
sets `cdn_base: ""` so images resolve from `static/media/` instead of R2.

### Publish a post

Remove `draft: true` from frontmatter, then commit and push:

```bash
git add -A
git commit -m "New post: my-post-slug"
git push
```

Cloudflare Pages auto-deploys on push to `main`. Build config:
- Framework: Hugo
- Build command: `hugo --gc --minify`
- Output directory: `public`
- Environment variable: `HUGO_VERSION=0.162.0`

### Import posts from another folder

```bash
cp /path/to/old-posts/*.md content/post/
```

As long as they have valid Hugo frontmatter (title, date, tags), they'll work.

### Add images to a post

Use the `{{< figure >}}` shortcode:

```markdown
{{< figure src="media/photo.jpg" caption="optional caption" >}}
```

For a hi-res lightbox with separate full-res file:

```markdown
{{< figure src="media/photo-2048.jpg" link="media/photo-fullres.jpg" caption="..." >}}
```

### Gallery grid

Wrap `{{< figure >}}` shortcodes in a paired `gallery` shortcode. Tiles are square,
3 per row on desktop, 2 on tablet, 1 on mobile.

```markdown
{{< gallery caption-effect="fade" hover-effect="shrink" >}}
{{< figure src="media/photo-a.jpg" >}}
{{< figure src="media/photo-b.jpg" >}}
{{< /gallery >}}
```

- `hover-effect`: `grow`, `zoom`, `shrink`, `slideup`, `slidedown`
- `caption-effect`: `fade`

Always use the paired form. The `dir=` form (`{{< gallery dir="..." >}}`) failed the build
for a test post with "shortcode must be closed or self-closed". Use the paired form instead.

### Local image workflow

During drafting, drop images in `static/media/` — Hugo serves them at `/media/file.jpg`.
No post content changes needed when you later upload to R2 and remove from `static/`.

`static/media/` is gitignored (draft images never committed).

### Upload images to R2

Export masters from darktable at 2048px long side, 85% quality JPEG, into `static/media/`.
Then run:

```bash
./upload-images.sh --dry-run     # preview: lists files not yet on R2
./upload-images.sh               # upload only files not yet on R2
./upload-images.sh --derivatives # also create NAME-1200.jpg copies, then upload
```

- The default compares `static/media/` with `r2:aadm-images/media/` by filename and
  uploads only the missing ones. Existing objects are never overwritten.
- `--derivatives` creates `NAME-1200.jpg` (long side 1200px, quality 85, EXIF stripped)
  for each master that lacks one. Derivatives are not used by any post yet.
- Derivatives are off by default until the impact on page weight is measured.
- Remove local copies afterwards if disk space matters: `rm static/media/my-photo.jpg`.

### Images to check or regenerate

Files in `static/media/` that do not meet the 2048px long-side rule (as of 2026-10-26).
Portraits exported with 2048px on the short side measure 2048x3072 and must be redone
at 1365x2048.

The `piccolagorai_*` set (66 files) was re-exported on 2026-10-26 and now meets the rule.

Oversized files (long side over 2048px), 7 files:

- `20170303_XPR2063.jpg` (2048x3084)
- `20171228_FUJ0031.jpg`, `20171228_FUJ0042.jpg`, `20171228_FUJ0062.jpg` (2048x3061)
- `20171229_FUJ0188.jpg` (2047x3061), `20171229_FUJ0211.jpg` (2048x3061)
- `usa1997_022.tif.jpg` (5450x3615, unresized)

Check again with:

```bash
cd static/media && identify -format '%w %h %f\n' * | awk '{l=($1>$2)?$1:$2; if(l>2048) print}'
```

### Production build

```bash
hugo --gc --minify
```

### Sync local images from R2

Pull all R2 images down to `static/media/` for local dev:

```bash
rclone sync r2:aadm-images/media/ static/media/ -P
```

## Architecture

- **Theme**: beautifulhugo (vendored, all customizations in site-level `layouts/` and `i18n/`)
- **Multilingual**: English default, Italian secondary
  - `.md` = Italian, `.en.md` = English
  - Language switcher appears only on posts with both versions
- **Images**: Cloudflare R2 via rclone; CDN base prepended by `{{< figure >}}` shortcode
- **Deployment**: Cloudflare Pages (auto-deploy on push)

### Key files

File                                 | Purpose                                                      
-------------------------------------| -------------------------------------------------------------
`hugo.yaml`                          | Main site config; includes `cdn_base`
`config/development/params.yaml`     | Local override: `cdn_base: ""`
`layouts/partials/`                  | 
...`head_custom.html`                | Global CSS overrides for fonts, spacing, nav, links, hover   
...`nav.html`                        | Navbar logic: hides TOC on homepage; shows language switcher 
...`shortcodes/beautifulfigure.html` | Figure shortcode with CDN prefix and caption below the image
`layouts/_default/archive.html`      | Archive page with year filter 
`layouts/_default/terms.html`        | Tags page with filter pills 
`i18n/it.yaml`                       | Localized strings; keeps English labels in Italian mode
`content/archive/_index.md`          | Archive landing page
`content/tags/_index.md`             | Tags landing page
`newpost.sh`                         | Creates new posts

## Custom styling

Fonts loaded from Google Fonts:
- **Lora** (`ital,wght@0,700;1,400;1,700`) — headings
- **PT Sans** (`ital,wght@0,400;0,700;1,400;1,700`) — body text
- **PT Sans Narrow** (`wght@400;700`) — navbar, post-meta, tags, sidebar

Theme overrides live in `layouts/` and `i18n/` (not in `themes/beautifulhugo/`).

## Updating the theme

```bash
rm -rf themes/beautifulhugo
git clone https://github.com/halogenica/beautifulhugo.git themes/beautifulhugo
rm -rf themes/beautifulhugo/.git
git add -A && git commit -m "Update beautifulhugo theme" && git push
```

## Interpost links

```markdown
[link text](/2010-08-19-my-next-camera.html)            # English post
[link text](/it/2019-04-30-moto-guzzi-v7.html)          # Italian post (needs /it/ prefix)
[link text]({{< ref "post/2010-08-19-my-next-camera.md" >}})  # build-time validation
```

## License

Content (text and photographs) is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).

You are free to share and adapt the material for non-commercial purposes, provided
you give appropriate credit. Commercial use requires permission.

## TO-DO

** draft posts only work in `content/post/`? not in `_drafts/`?