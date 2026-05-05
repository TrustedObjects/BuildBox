# Documentation build

First of all, generate (or update) the API documentation by running:
```
src/dev/generate_apidoc.sh ../src/
```

Call this script every time the API documentation is updated.

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
