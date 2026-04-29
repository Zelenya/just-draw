## Development

```sh
npm install
npm run start
```

The dev server runs at [http://localhost:1234](http://localhost:1234). It watches app code, `content/site.json`, and Tailwind CSS.

Useful commands:

```sh
npm run bundle
npm test
npm run format
```

## Deployment

`npm run deploy` builds `/dist` and publishes it to the `gh-pages` branch.

GitHub Pages should serve the `gh-pages` branch from the repository root. The production build assumes the site is hosted at `/just-draw`.

## Content

Exercises live in `content/site.json`.

Each exercise has:

- `title`
- `slugSegment`
- `tags`
- `excerpt`
- `heroImage`
- `body`

`body` is an array of simple content blocks. Supported block kinds are `paragraph`, `heading`, `quote`, `list`, `links`, and `images`.
