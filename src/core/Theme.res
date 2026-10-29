// Everything that makes one variation of the game look, sound and read
// differently. The engine only sees `rules`.
type logCopy = {title: string, subject: string, granted: string, denied: string, empty: string}

type copy = {
  appName: string,
  crumb: string,
  title: string,
  intro: React.element,
  baseLabel: string,
  capturesLabel: string,
  tierLabel: string,
  overHeading: string,
  overSummary: (~captures: int, ~score: int) => string,
  log: logCopy,
  // Floating labels on the playfield.
  captured: string,
  missed: string,
  breached: string,
  wasted: string,
}

type bonus = {
  spec: Engine.bonusSpec,
  caption: string,
  cheer: string,
  width: float,
  height: float,
  // Draws the sprite with its top-left at the origin.
  draw: (Canvas2d.t, Engine.bonus, ~time: float) => unit,
}

type backdrop = {
  update: float => unit,
  draw: (Canvas2d.t, ~time: float) => unit,
  // Viewport coordinates of a captured word.
  capture: (~x: float, ~y: float) => unit,
  bonus: Engine.bonusSpec => unit,
}

// A theme's own playfield effects and set dressing, living alongside the
// core's sparks and labels. Coordinates are stage coordinates.
type scene = {
  onEvent: Engine.event => unit,
  update: float => unit,
  // Behind the words, just after the background.
  drawBack: (Canvas2d.t, ~time: float) => unit,
  // In front of everything else.
  drawFront: (Canvas2d.t, ~time: float) => unit,
}

type stage = {
  width: float,
  height: float,
  // Asks for a screen shake of the given strength (0 to 1); ignored under
  // prefers-reduced-motion.
  shake: float => unit,
}

type look = {
  labelFont: string,
  bonusFont: string,
  ink: string,
  inkMuted: string,
  match: string,
  captureTint: string,
  missTint: string,
  bonusTint: string,
  sparks: array<string>,
  background: (Canvas2d.t, ~width: float, ~height: float, ~time: float) => unit,
  word: (Canvas2d.t, Engine.word, ~input: string, ~missed: bool, ~time: float) => unit,
  // The full width a word occupies on the playfield (used for collisions).
  measure: (Canvas2d.t, string) => float,
  base: (Canvas2d.t, Shield.t, ~y: float) => unit,
  makeBackdrop: (~width: float, ~height: float, ~window: Dom2.rect) => backdrop,
  makeScene?: stage => scene,
}

type sound = {
  capture: unit => unit,
  miss: unit => unit,
  breach: unit => unit,
  bonus: Engine.bonusSpec => unit,
}

type t = {
  id: string,
  name: string,
  // Applied to the scene so CSS can restyle the window chrome.
  className: string,
  logo: React.element,
  copy: copy,
  vocabulary: array<string>,
  bonuses: array<bonus>,
  tiers: array<Tier.t>,
  defaultTier: string,
  look: look,
  sound: sound,
}

let rules = theme => {
  Engine.vocabulary: theme.vocabulary,
  bonuses: theme.bonuses->Array.map(bonus => bonus.spec),
}

let art = (theme, spec: Engine.bonusSpec) =>
  theme.bonuses->Array.find(b => b.spec.word == spec.word)

let defaultTier = theme =>
  theme.tiers->Tier.find(theme.defaultTier)->Option.getOr(theme.tiers->Array.getUnsafe(0))
