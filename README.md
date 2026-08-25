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

# 5. when done, upload images to R2
rclone copy static/media/ r2:aadm-images/media/ -P

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

### Local image workflow

During drafting, drop images in `static/media/` — Hugo serves them at `/media/file.jpg`.
No post content changes needed when you later upload to R2 and remove from `static/`.

`static/media/` is gitignored (draft images never committed).

### Resize and upload images to R2

```bash
# resize to 2048px long side, 85% quality JPEG, then:
rclone copy /path/to/images/ r2:aadm-images/media/ -P
# remove from static/media/ after uploading
rm static/media/my-photo.jpg
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

- **Hugo** v0.162.0 (extended) at `~/.local/bin/hugo`
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
