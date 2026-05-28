# AAdM Blog — Migration Session

## What was done

The original blog was a **Pelican** static site (Python) using the `pelican-bootstrap3` theme, deployed to AWS S3 via `make s3_upload`. It hasn't been updated since 2019.

We decided to migrate to **Hugo** + **Cloudflare Pages** + **Cloudflare R2** (for images).

### Completed steps

1. **Backed up old blog** — initialized a git repo at `/home/aadm/Documents/blog` with all original Pelican content committed.

2. **Installed Hugo** (v0.161.1 extended edition) at `~/.local/bin/hugo`:

   ```bash
   wget https://github.com/gohugoio/hugo/releases/download/v0.162.0/hugo_0.162.0_linux-amd64.tar.gz -O /tmp/hugo.tar.gz
   tar xzf /tmp/hugo.tar.gz -C /tmp/
   cp /tmp/hugo ~/.local/bin/hugo
   hugo version
   ```
   Ensure `~/.local/bin` is in your `$PATH`.

   Alternative: install via snap for automatic updates (`sudo snap install hugo`).

3. **Created new Hugo site** at `/home/aadm/Documents/aadm-hugo/` with:
   - `hugo.yaml` — multilingual config (Italian default, English secondary), preserved old URL structure (`/:year-:month-:day-:slug.html`), pagination, taxonomies
   - Custom theme `aadm-theme` — Bootstrap 5 with the old "readable" look (Roboto body, PT Serif headings, dark navbar, sidebar with recent posts + tags)
   - i18n translations for Italian and English (sidebar labels, nav text)

4. **Migrated all content** via `migrate.py`:
   - 275 blog posts from Pelican to Hugo frontmatter format
   - 5 pages (about, projects, 365-valentina, northbound, un-giorno-al-lago)
   - 23 posts correctly tagged as English (`.en.md`), rest default to Italian
   - Draft post preserved (`2019-12-13-amazons3.md`)

5. **Created shortcodes**:
   - `{{< figure src="media/file.jpg" caption="..." >}}` — R2-hosted images via beautifulfigure (PhotoSwipe lightbox, CDN base prepended automatically)
   - `figure` shortcode copied to `layouts/shortcodes/figure.html` to override Hugo's built-in and route through beautifulfigure

6. **Hugo dev server** runs at `http://localhost:1313/`.

### Remaining steps

- Upload remaining images (pizza, kyllesvatnet, etc.) to R2 bucket at 2048px long side, 85% quality JPEG

### Cloudflare R2 setup

1. **R2 bucket**: Create bucket named `aadm-images`, enable public access (Public Bucket URL).
2. **API tokens**: In Cloudflare R2 dashboard, create **Account API Token** with **Object read & write** permissions. Copy Access Key ID and Secret Access Key.
3. **rclone config**:

   ```bash
   rclone config
   # Choose "Cloudflare R2", enter Account ID, Access Key ID, Secret Access Key
   ```

4. **Upload images**:

   ```bash
   rclone copy /home/aadm/Documents/blog/content/images/ r2:aadm-images/media/ -P
   ```

   **Image sizing rule**: resize to **2048px long side, 85% quality JPEG** before uploading.
   Hugo does not resize CDN-hosted images. The blog column is ~900px wide; 2048px gives 2x
   retina headroom and is comfortable for lightbox full-screen viewing.

5. **Update `cdn_base`** in `hugo.yaml:30` with the Public Bucket URL from step 1.

### Key Cloudflare Pages setup

- **Git init & push**:

  ```bash
  cd /home/aadm/Documents/aadm-hugo
  git init
  git add -A
  git commit -m "Initial commit: Hugo blog migrated from Pelican"
  git remote add origin git@github.com:aadm/aadm-blog.git
  git push -u origin main
  ```

- **Pages build config**: Framework = Hugo, Build command = `hugo --gc --minify`, Output = `public`, env `HUGO_VERSION=0.161.1`.

### Key commands

```bash
# Preview locally
hugo server --buildDrafts

# Production build
hugo --gc --minify

# Upload images to R2
rclone copy /path/to/images/ r2:aadm-images/media/ -P

# See Hugo after edits
hugo server
```

### Image shortcodes

Use `{{< figure >}}` for all images in posts. It routes through beautifulhugo's `beautifulfigure`
shortcode (PhotoSwipe lightbox) and prepends `cdn_base` from `hugo.yaml` automatically.

```markdown
{{< figure src="media/file.jpg" caption="optional caption" >}}
```

For hi-res lightbox with a separate full-res file:

```markdown
{{< figure src="media/file-2048.jpg" link="media/file-fullres.jpg" caption="..." >}}
```

The `img` shortcode (old custom shortcode from `aadm-theme`) is no longer used. All existing
`{{< img >}}` calls have been converted to `{{< figure >}}`.

**Key files**:
- `layouts/shortcodes/figure.html` — overrides Hugo's built-in figure, routes to beautifulfigure
- `layouts/shortcodes/beautifulfigure.html` — delegates to partial
- `layouts/partials/shortcodes/beautifulfigure.html` — prepends `cdn_base` to src; also suppresses page-relative path fallback

### Multilingual notes

- **Language file naming**: `.md` = English (default), `.it.md` = Italian, `.en.md` = (not needed since English is default).
- **Homepage shows all posts** (EN + IT) via `layouts/index.html` override — iterates `.Site.Home.AllTranslations` to collect posts from all languages.
- **Italian UI labels** overridden in `i18n/it.yaml` to always show English text (menu, "Posted on", etc.) even when browsing in Italian mode.
- **Language switcher** appears per-post when both EN and IT versions of the same filename stem exist (e.g., `best-sensor-ever.md` + `best-sensor-ever.it.md`).

To **revert** to normal Hugo multilingual behavior (separate EN/IT listings per language):

```bash
# 1. Remove the index override
rm layouts/index.html

# 2. Remove the i18n override (restore original Italian labels)
rm i18n/it.yaml

# 3. (Optional) Delete duplicate language slugs for archive/tags pages
#    so EN lists only EN posts, IT lists only IT posts
```

This restores Hugo's default: English homepage shows only `.md` posts, Italian homepage shows only `.it.md` posts, and the language switcher fully translates the UI.

### Directory structure

```
/home/aadm/Documents/
├── blog/                    # Old Pelican site (backup, git repo)
│   ├── content/             # Original markdown posts
│   ├── output/              # Old generated HTML (57 MB)
│   ├── pelican-plugins/     # Git submodules
│   ├── pelicanconf.py
│   ├── publishconf.py
│   ├── tasks.py
│   └── Makefile
├── aadm-blog/               # Hugo site (git repo, deployed on Cloudflare Pages)
│   ├── content/
│   │   ├── post/            # Blog posts (275)
│   │   ├── page/            # Standalone pages (about, projects, 365-valentina, etc.)
│   │   └── archive/         # Archive listing
│   ├── themes/beautifulhugo/ # Theme (vendored, no .git — modifications via site dir)
│   ├── layouts/             # Site-level overrides (take priority over theme)
│   │   ├── index.html       # Homepage: shows all posts across languages
│   │   └── partials/
│   │       ├── header.html  # No big header on homepage, minimal title+meta on posts
│   │       ├── footer.html  # Copyright with now.Year
│   │       └── head_custom.html  # CSS overrides (spacing, navbar clearance)
│   ├── i18n/
│   │   └── it.yaml          # English UI labels even in Italian mode
│   ├── static/
│   │   └── favicon.png
│   ├── hugo.yaml
│   ├── newpost.sh           # Helper: creates YYYY-MM-DD-slug.lang.md
│   └── migrate.py           # Pelican-to-Hugo migration script (one-time use)
```

### Theme modifications

All changes are in **site directory** (`layouts/`, `i18n/`), **not** in `themes/beautifulhugo/`. Hugo's template lookup order gives priority to site-level files, so the theme directory itself is untouched.

| Site file                           | What it does                                                          |
|-------------------------------------|-----------------------------------------------------------------------|
| `layouts/index.html`                | Homepage: all posts across languages, paginated via `hugo.Sites`      |
| `layouts/_default/archive.html`     | Archive: flat list with year headings + filter buttons, all languages |
| `layouts/_default/terms.html`       | Tags: flat list with tag headings + filter pills, all languages       |
| `layouts/partials/nav.html`         | TOC button hidden on homepage; language switcher only on `.IsPage`    |
| `layouts/partials/header.html`      | Post page header: title + post-meta in `<p class="post-meta">`        |
| `layouts/partials/footer.html`      | Copyright with `now.Year`                                             |
| `layouts/partials/head_custom.html` | CSS overrides (fonts, spacing, nav, links)                            |
| `i18n/it.yaml`                      | English UI labels even in Italian mode                                |

### Custom styling (`layouts/partials/head_custom.html`)

**To change fonts**, edit the Google Fonts URLs at lines 1-3 and the corresponding `font-family` rules.

- **Body font**: PT Sans weight 400, 18px
- **Headings (h1-h6)**: Lora italic bold
- **Post entry text** (`.post-preview .post-entry`): `font-family: inherit` (PT Sans)
- **Post meta** (`.post-preview .post-meta`, `.post-heading .post-meta`): PT Sans Narrow
- **Blog tags inline** (`.blog-tags`): PT Sans Narrow
- **Navbar links**: PT Sans Narrow, text-transform lowercase, font-size 20px
- **Content links** (`.blog-post a`, `.post-entry a`): no underline, `border-bottom: 1px dotted`, pale yellow background on hover
- **Post title on individual page** (`.intro-header .post-heading h1`): 30px (36px desktop), color #404040
- **Page/section headings** (archive, tags, about, projects): 48px (60px desktop), left-aligned, Lora italic bold — overrides theme default of 50px centered
- **Intro-header margin**: 90px (105px desktop) to clear fixed navbar
- **Container padding**: 70px top; 20px when preceded by header-section

Fonts loaded from Google Fonts:
- Lora: `ital,wght@0,700;1,400;1,700`
- PT Sans: `ital,wght@0,400;0,700;1,400;1,700`
- PT Sans Narrow: `wght@400;700`

### Tags page (`layouts/_default/terms.html`)

- Tag names rendered as PT Sans bold 28px headings with post count in PT Sans Narrow 14px `#999`
- Posts under each tag in PT Sans 18px, yellow hover, no underline — same as archive list
- Filter pills at top (reuses `.archive-year-btn` styles) — JS show/hide by tag
- Page title set via `content/tags/_index.md` (title: tags, lowercase)

### Archive page (`layouts/_default/archive.html`)

- Flat chronological list grouped by year, all languages via `hugo.Sites`
- Year filter buttons at top, JS show/hide
- Year headings: PT Sans bold 28px
- Post titles: PT Sans 18px (inherited), date in `#999`
- Page title set via `content/archive/_index.md` (title: archive, lowercase)

### Projects page (`content/page/projects.md`)

- Plain semantic HTML (`div.project-item` with `h4` + `p`)
- Spacing: `margin-bottom: 1.5rem` per item, description in `#666`
- Old Bootstrap 3 `.panel` markup removed

**Updating the theme:** You can clone a fresh copy from GitHub without losing any customizations. Site-level overrides always win. Steps:

```bash
rm -rf themes/beautifulhugo
git clone https://github.com/halogenica/beautifulhugo.git themes/beautifulhugo
# Delete the embedded .git to avoid submodule issues
rm -rf themes/beautifulhugo/.git
git add -A && git commit -m "Update beautifulhugo theme" && git push
```

### Interpost links

All `{filename}` Pelican links have been converted to Hugo permalinks. The two patterns that existed:

- `{filename}YYYY-MM-DD-slug.md` → `/YYYY-MM-DD-slug.html`
- `{filename}/pages/slug.md` → `/slug/`

For new posts, use absolute paths:

```markdown
[my next camera](/2010-08-19-my-next-camera.html)
```

Alternatively, use Hugo's `ref` shortcode for build-time validation of broken links:

```markdown
[my next camera]({{< ref "post/2010-08-19-my-next-camera.md" >}})
```
