# Documentation build

Several parts of the site are generated, all of them by `npm run build`:

| Generated file | Script | Source |
|---|---|---|
| `src/dev/api.md` | `src/dev/generate_apidoc.sh ../src/` | the `##` comments of the API files |
| `src/parts/news.md` | `src/dev/generate_news.sh ../ChangeLog src/parts/news.md` | the `ChangeLog` |
| `src/public/cheatsheet.pdf` | `src/dev/generate_cheatsheet.sh` | `src/dev/cheatsheet.html.template` |
| `src/public/*.png` diagrams | `src/dev/generate_diagrams.sh` | the SVG files of `src/dev/diagrams/` |

None is versioned except the diagrams, see below. To regenerate the API
documentation alone, without building the site:
```
src/dev/generate_apidoc.sh ../src/
```

## Diagrams

The diagrams of the site are drawn as SVG in `src/dev/diagrams/`, which is
their source: never edit the PNG. `src/dev/generate_diagrams.sh` renders each
of them to `src/public/<name>.png`, at twice its SVG size so it stays sharp on
high density displays, and the pages reference it as `/<name>.png`.

An SVG accompanied by a `<name>.dark.css` file is rendered a second time to
`src/public/<name>_dark.png`, with that stylesheet appended to the one of the
SVG. The dark variant holds colours only: the geometry and the type have a
single source, so a diagram is never drawn twice. This is why every colour of
an SVG belongs to its `<style>` element, never to a `fill` or a `stroke`
attribute.

A page carries both PNG and lets the theme hide one, through the
`.bbx-diagram-light` and `.bbx-diagram-dark` classes of
`src/.vitepress/styles/index.css`:

```html
<img class="bbx-diagram-light" src="/foo.png" alt="...">
<img class="bbx-diagram-dark" src="/foo_dark.png" alt="...">
```

Two images rather than one swapped source, so the right one is there at first
paint. VitePress prefixes the `src` of a raw `<img>` with the site base, so
this keeps working on the versioned deploys.

A diagram is rendered only when its PNG is missing or older than its sources,
or than the script itself, so a build that changes no diagram costs nothing.
Pass `--force` to render them all.

Rendering uses the first of `rsvg-convert`, Inkscape, ImageMagick, Chromium or
Chrome found on the machine. When none is installed the diagrams are skipped
with a warning instead of failing the build.

Unlike the other generated files the PNG files are committed, because a missing
diagram would leave a broken image in the pages of anyone building without a
renderer. A change to an SVG source is therefore committed together with its
regenerated PNG.

## Cheat sheet

`src/dev/cheatsheet.html.template` is a single page A4 sheet of the usual
commands, written for people who need to fetch, build and test a project
without being developers. `src/dev/generate_cheatsheet.sh` renders it to
`src/public/cheatsheet.pdf`, which the build copies to the site root and serves
as `/cheatsheet.pdf`.

Rendering uses a headless Chromium or Chrome. When none is installed the sheet
is skipped with a warning instead of failing the build, so the site stays
buildable without a browser. The script also warns when the result spans more
than one page, which is a layout regression: check it after editing the
template, with `src/dev/generate_cheatsheet.sh` alone.

`npm run dev` does not regenerate it, being a static asset: run the script once
to get the download working locally.

The releases news of the home page comes from the `ChangeLog`, so publishing a
release only requires the `ChangeLog` entry. The last three releases are shown,
with at most four entries each: pass a count as third argument, or set `ITEMS`,
to change it. The version, and the `and N more` note when entries are truncated,
link to the GitHub release page of that version (`releases/tag/<VERSION>`, tags
being plain version numbers).

A release needing a migration also shows a discreet `Migration required` badge linking to it. It is
detected from `src/user/migration.md` itself: a section titled
`## From <VERSION> to <VERSION>` marks the second version as needing a
migration, and the link targets that section. Documenting a migration is
therefore enough, there is nothing to declare in the `ChangeLog`.

## Development documentation

To test live documentation, which is automatically refreshed on changes:
```
npm run dev
```

## Release documentation

### First-time setup

Create a `versions.json` file at the root of the web server before the first release:
```json
{
  "latest": "2.0.0",
  "versions": [
    { "tag": "2.0.0", "path": "/" }
  ]
}
```

The version selector is hidden when only one version is listed.

### Building and deploying a release (e.g. `2.0.0`)

**Step 1:** Build for the versioned subdirectory:
```
BASE_URL=/v/2.0.0/ SITE_URL=https://buildbox.trusted-objects.com npm run build
```
Upload `src/.vitepress/dist/` to the server at `/v/2.0.0/`.

The build warns when `BASE_URL` does not match the version of the tree being
built, which is the one mistake this step cannot survive: the pages of a
versioned build carrying the base of another version load that version's
assets, which exist, and its router then redirects every reader to it. The site
answers 200 and serves the wrong version.

**Step 2:** Build for root (latest):
```
BASE_URL=/ SITE_URL=https://buildbox.trusted-objects.com npm run build
```
Upload `src/.vitepress/dist/` to the server root `/`, overwriting the previous latest.

**Step 3:** Update `versions.json` on the server:
- Change the previous latest entry from `"path": "/"` to `"path": "/v/<PREV>/"`.
- Add a new entry at the top: `{ "tag": "2.0.0", "path": "/" }`.
- Update `"latest": "2.0.0`.

Old version directories on the server are never touched again. The version
selector on all deployed versions fetches `/versions.json` at runtime, so the
up-to-date list appears everywhere without any rebuild.

### Testing the build locally

```
python -m http.server --directory src/.vitepress/dist
```

Reach http://localhost:8000 from the browser.
To test the version selector locally, place a `versions.json` file in
`src/.vitepress/dist/` before starting the server.
