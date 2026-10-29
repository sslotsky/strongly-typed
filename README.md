[![Netlify Status](https://api.netlify.com/api/v1/badges/52566609-fced-45cb-9861-cd5dc5322953/deploy-status)](https://app.netlify.com/sites/strongly-typed/deploys)

# Strongly Typed

A typing game: words fall, you type them before they land. Every so often a
bonus drifts across the scene; type it for a power-up.

The game is one theme-able core plus themes:

- **Pollinator Lawn**: autumn leaves carry native seeds. Sow each one before it
  lands; every seed plays the next note of a tune. The monarch pollinates
  everything, the bumblebee slows the wind, the cardinal doubles points and the
  rabbit regrows the lawn.

## Running locally

```sh
npm install
npm run dev     # http://localhost:5173, ?theme=<id> to open a theme
npm test        # engine tests
npm run build   # static site in dist/
```

## How it fits together

- `src/core/Engine.res` is pure: state in, state plus events out. Movement is
  time-based (`dt`), so the game plays at the same speed on any display.
- `src/core/Theme.res` is the contract a theme fills in: vocabulary, tiers,
  bonuses (`ClearAll`, `SlowTime`, `DoublePoints`, `Repair`), copy, and the
  renderers for words, the base, bonus sprites and the backdrop, plus sounds.
- `src/themes/*` holds the themes; `src/Themes.res` lists them.
- A site chooses which themes it offers with `VITE_THEMES` (comma-separated
  ids, in switcher order). Unset offers every theme. This site sets it in
  `netlify.toml`.
