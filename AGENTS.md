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
   - `{{< img "path" "alt" "caption" >}}` — R2-hosted images with CDN base URL configurable in `hugo.yaml`

6. **Hugo dev server** runs at `http://localhost:1313/`.

### Remaining steps

- Initialize git repo in `aadm-hugo/` and push to GitHub/GitLab
- Upload images to R2 via rclone
- Create Cloudflare Pages project connected to the git repo
- Set up auto-deploy on `git push`
- (Optional) Buy custom domain via Cloudflare Registrar
- Fix remaining `{filename}` Pelican links in 27 posts (listed below)
- Upload remaining images (pizza, kyllesvatnet, etc.) to R2 bucket

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
└── aadm-hugo/               # New Hugo site
    ├── content/
    │   ├── post/            # Blog posts (275)
    │   ├── archive/
    │   ├── about.md
    │   ├── projects.md
    │   ├── 365-valentina.md
    │   ├── northbound.md
    │   └── un-giorno-al-lago.md
    ├── themes/aadm-theme/   # Custom Bootstrap 5 theme
    │   ├── layouts/         # Templates
    │   ├── static/          # CSS, JS
    │   └── i18n/            # Translations
    ├── static/favicon.png
    ├── hugo.yaml
    ├── newpost.sh              # Helper script to create new posts
    └── migrate.py

### Posts with broken `{filename}` Pelican links

These 27 posts still contain `{filename}` references (e.g. `{filename}2012-07-31-panasonic-gf1-late-review.md`) that need to be replaced with Hugo-style permalink URLs (`/2012-07-31-panasonic-gf1-late-review.html`).

- `content/post/2010-09-11-it-was-unintentional.en.md`
- `content/post/2012-07-31-panasonic-gf1-late-review.en.md`
- `content/post/2012-07-31-panasonic-gf1-late-review.it.md`
- `content/post/2012-09-21-thoughts-on-d7000.en.md`
- `content/post/2013-02-22-d600-first-impressions.en.md`
- `content/post/2013-11-11-photographic-projects.en.md`
- `content/post/2013-11-11-photographic-projects.it.md`
- `content/post/2014-01-04-valentina-365.it.md`
- `content/post/2014-01-15-networked-photography.en.md`
- `content/post/2014-01-15-networked-photography.it.md`
- `content/post/2014-05-26-after-a-long-pause.en.md`
- `content/post/2014-05-26-after-a-long-pause.it.md`
- `content/post/2015-11-20-pelican-lives.en.md`
- `content/post/2016-01-10-nicolai-mojo.en.md`
- `content/post/2016-02-02-a-little-camera.en.md`
- `content/post/2016-02-12-rock-physics-templates.en.md`
- `content/post/2016-04-02-geopaesaggi-libretto.en.md`
- `content/post/2016-04-02-geopaesaggi-libretto.it.md`
- `content/post/2016-10-12-fuji-me-too.en.md`
- `content/post/2016-10-16-backcountry-pyrenees.en.md`
- `content/post/2017-02-02-late-review-of-the-fuji-xpro1.en.md`
- `content/post/2017-07-11-thoughts-on-photography-1.en.md`
- `content/post/2017-10-06-bari.en.md`
- `content/post/2017-10-06-bari.it.md`
- `content/post/2018-03-05-the-end-of-gear-addiction.en.md`
- `content/post/2019-08-05-aggiornamenti-guzzi-v7.it.md`
- `content/post/2019-08-05-the-end-of-gear-addiction-addendum.en.md`
```
