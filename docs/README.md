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

If you have an error "digital envelope routines::unsupported", before the
NPM invocation you have to run:
```
export NODE_OPTIONS=--openssl-legacy-provider
```

## Release documentation

To create the documentation release:
```
BASE_URL="/" npm run build
```

Replace `BASE_URL` with the relevant value for the server.
Below we assume it is `/`.

If you have an error "digital envelope routines::unsupported", before the
NPM invocation you have to run:
```
export NODE_OPTIONS=--openssl-legacy-provider
```

The documentation is available at `src/.vuepress/dist/` and you can test it
by running:
```
python -m http.server --directory src/.vuepress/dist
```

and reaching http://localhost:8000 from the browser.

