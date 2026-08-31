# Documentation build

Two parts of the site are generated, both by `npm run build`:

| Generated file | Script | Source |
|---|---|---|
| `src/dev/api.md` | `src/dev/generate_apidoc.sh ../src/` | the `##` comments of the API files |
| `src/parts/news.md` | `src/dev/generate_news.sh ../ChangeLog src/parts/news.md` | the `ChangeLog` |

Neither is versioned. To regenerate the API documentation alone, without
building the site:
```
src/dev/generate_apidoc.sh ../src/
```

The releases news of the home page comes from the `ChangeLog`, so publishing a
release only requires the `ChangeLog` entry. The last three releases are shown,
with at most four entries each: pass a count as third argument, or set `ITEMS`,
to change it. The version, and the `and N more` note when entries are truncated,
link to the GitHub release page of that version (`releases/tag/<VERSION>`, tags
being plain version numbers).

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
