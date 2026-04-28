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

To create the documentation release:
```
SITE_URL=https://buildbox.trusted-objects.com BASE_URL="/" npm run build
```

The documentation is available at `src/.vitepress/dist/` and you can test it
by running:
```
python -m http.server --directory src/.vitepress/dist
```

and reaching http://localhost:8000 from the browser.

