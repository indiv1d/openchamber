# Docs Source Deployment

This repo publishes docs **source artifacts**.

Rendering and hosting still happen in `openchamber-website` (`apps/docs`).

## Manual package

This fork does not use GitHub Actions. Package the docs source by hand:

```bash
bun run docs:validate
mkdir -p dist
tar -czf "dist/openchamber-docs-source-$(git rev-parse --short HEAD).tar.gz" \
  -C packages/docs content sidebar.config.json
```

`docs:validate` checks frontmatter and sidebar links. The archive contains the
MDX pages and the sidebar configuration.

## Publishing

Upload the archive to the website pipeline, or check out this repository at the
built commit in `openchamber-website` and run `docs:sync` there. The website
build and Cloudflare Pages deployment live in `openchamber-website`.

This fork does not send cross-repository events and does not need
`OPENCHAMBER_WEBSITE_REPO_TOKEN`.
