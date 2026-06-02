---
title: bari collection 1
date: 2018-01-15
slug: bari-collection-1-en
tags:
- photo
draft: true
---

[Another](2017-10-06-bari.html) small collection of photos from my visit to Bari in December 2017.

{{< gallery dir="/media/bari-2017-12/" caption-effect="fade" >}}
{{< /gallery >}}

**warning** cannot use `<gallery>` shortcode, see log file below:

```
2026-05-31T22:16:18.852994Z	Cloning repository...
2026-05-31T22:16:20.014608Z	From https://github.com/aadm/aadm-blog
2026-05-31T22:16:20.015034Z	 * branch            80d55512ffbdd2e343733ed3a28bfa0c4c31b196 -> FETCH_HEAD
2026-05-31T22:16:20.01516Z
2026-05-31T22:16:20.112117Z	HEAD is now at 80d5551 fixes and improvements
2026-05-31T22:16:20.112414Z
2026-05-31T22:16:20.250188Z
2026-05-31T22:16:20.250699Z	Using v2 root directory strategy
2026-05-31T22:16:20.265514Z	Success: Finished cloning repository files
2026-05-31T22:16:21.640562Z	Checking for configuration in a Wrangler configuration file (BETA)
2026-05-31T22:16:21.641296Z
2026-05-31T22:16:21.797817Z	No Wrangler configuration file found. Continuing.
2026-05-31T22:16:22.853648Z	Updating hugo to main
2026-05-31T22:16:22.853998Z	Already on 'main'
2026-05-31T22:16:22.854195Z	Your branch is up to date with 'origin/main'.
2026-05-31T22:16:23.378584Z	Detected the following tools from environment: hugo@extended_0.162.0
2026-05-31T22:16:23.378821Z	Installing hugo extended_0.162.0
2026-05-31T22:16:23.443192Z	* Downloading hugo release extended_0.162.0...
2026-05-31T22:16:24.778454Z	hugo extended_0.162.0 installation was successful!
2026-05-31T22:16:24.911502Z	Executing user command: hugo --gc --minify
2026-05-31T22:16:25.063269Z	Start building sites …
2026-05-31T22:16:25.063568Z	hugo v0.162.0-076dfe13d0f789e3d9586b192f8f7f3329c26990+extended linux/amd64 BuildDate=2026-05-26T13:53:44Z VendorInfo=gohugoio
2026-05-31T22:16:25.063648Z
2026-05-31T22:16:25.216892Z	Total in 156 ms
2026-05-31T22:16:25.217879Z	ERROR error building site: render: [en v1.0.0 guest] failed to render pages: render of "/" failed: "/opt/buildhome/repo/layouts/index.html:20:15": execute of template failed: template: index.html:20:15: executing "main" at <partial "post_preview" .>: error calling partial: "/opt/buildhome/repo/themes/beautifulhugo/layouts/partials/post_preview.html:27:11": execute of template failed: template: _partials/post_preview.html:27:11: executing "_partials/post_preview.html" at <.Content>: error calling Content: "/opt/buildhome/repo/content/post/2018-01-15-bari-misc.en.md:11:1": failed to render shortcode "gallery": failed to process shortcode: "/opt/buildhome/repo/themes/beautifulhugo/layouts/shortcodes/gallery.html:10:16": execute of template failed: template: _shortcodes/gallery.html:10:16: executing "_shortcodes/gallery.html" at <readDir (print "/static/" .)>: error calling readDir: failed to read directory "/static//media/bari-2017-12/": open /opt/buildhome/repo/static/media/bari-2017-12: no such file or directory
2026-05-31T22:16:25.221926Z	Failed: Error while executing user command. Exited with error code: 1
2026-05-31T22:16:25.228295Z	Failed: build command exited with code: 1
2026-05-31T22:16:25.922126Z	Failed: error occurred while running build command
```

