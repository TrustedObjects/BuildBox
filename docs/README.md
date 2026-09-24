# BuildBox documentation

The BuildBox documentation site, built with [VitePress](https://vitepress.dev).
The pages are written in Markdown in `src/`.

## Building the documentation

Install the dependencies once:
```
npm install
```

### Development

To browse the documentation live, refreshed automatically on every change:
```
npm run dev
```

### Release

The site is deployed once per version: the latest one at the root of the web
server, the older ones under `/v/<VERSION>/`. A version selector lists them,
reading a `versions.json` file served at the site root.

Before the first release, create that `versions.json` on the server:
```json
{
  "latest": "2.0.0",
  "versions": [
    { "tag": "2.0.0", "path": "/" }
  ]
}
```

The selector is hidden while a single version is listed.

To deploy a release, for instance `2.0.0`:

1. Build it for its versioned directory, and upload `src/.vitepress/dist/` to
   `/v/2.0.0/` on the server:
   ```
   BASE_URL=/v/2.0.0/ SITE_URL=https://buildbox.trusted-objects.com npm run build
   ```
   The build warns when `BASE_URL` does not match the version being built:
   do not ignore it, such a site would redirect its readers to another version.
2. Build it for the root, and upload `src/.vitepress/dist/` to `/`, replacing
   the previous latest:
   ```
   BASE_URL=/ SITE_URL=https://buildbox.trusted-objects.com npm run build
   ```
3. Update `versions.json` on the server: move the previous latest to
   `"path": "/v/<PREV>/"`, add `{ "tag": "2.0.0", "path": "/" }` at the top,
   and set `"latest": "2.0.0"`.

Older versions are never touched again: they all read the same
`/versions.json`, so the new list shows up everywhere without a rebuild.

To check a build locally, serve it and open http://localhost:8000:
```
python -m http.server --directory src/.vitepress/dist
```
Drop a `versions.json` in `src/.vitepress/dist/` to try the version selector.

## What the build does

Some pages and files are generated before VitePress builds the site:

1. **API reference**: `src/dev/api.md`, extracted from the comments of the
   BuildBox API files (`../src/_*.sh`).
2. **Releases news** of the home page, taken from the `ChangeLog`.
3. **Diagrams**, rendered from SVG to PNG.
4. **Cheat sheet**, rendered to PDF.

`npm run dev` only runs steps 2 and 3. The generated files are never edited by
hand: edit their source instead.

## How the documentation works

**Diagrams** are drawn as SVG in `src/dev/diagrams/` and rendered to PNG in
`src/public/`, with a dark theme variant when needed. The PNG files are
committed, so the site builds even without an SVG renderer installed: commit a
modified SVG together with its regenerated PNG.

**Figures** are SVG of `src/dev/figures/` inserted as is into the pages, so
they follow the site theme and react to the page. The project layout figure,
for instance, is shown by several pages of the user manual, each one
highlighting the part it is about:
```md
<ProjectLayout highlight="target" />
```

**Migrations**: a breaking change is described in `src/user/migration.md`, and
the concerned pages link to it.

## Other files

**Cheat sheet**: `src/dev/cheatsheet.html.template` is a one page summary of
the usual commands, for people who build and test a project without being
developers. The build renders it to `/cheatsheet.pdf` with Chromium or Chrome,
and skips it when neither is installed. Run `src/dev/generate_cheatsheet.sh`
alone to check it after an edit, or to get the download working with
`npm run dev`.

**Releases news**: publishing a release on the home page only takes its
`ChangeLog` entry. A release that requires a migration gets a badge linking to
it on its own.
