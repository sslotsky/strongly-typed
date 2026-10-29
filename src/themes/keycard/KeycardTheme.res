// Agentically Typed: resources fall, typing one is a token exchange.
open Canvas2d

let vocabulary = [
  "GitHub",
  "Linear",
  "Slack",
  "Notion",
  "Google Drive",
  "Gmail",
  "Calendar",
  "Salesforce",
  "Snowflake",
  "Postgres",
  "S3 bucket",
  "Stripe",
  "Jira",
  "Confluence",
  "Datadog",
  "Sentry",
  "Zendesk",
  "HubSpot",
  "Figma",
  "Vercel",
  "Supabase",
  "BigQuery",
  "MCP server",
  "Vault secret",
  "Kubernetes",
  "OpenAI",
  "Anthropic",
  "Asana",
  "Dropbox",
  "PagerDuty",
  "repo:write",
  "calendar.readonly",
  "issues:read",
  "chat:write",
]

let tiers: array<Tier.t> = [
  {
    id: "haiku",
    name: "Haiku",
    blurb: "A gentle pace",
    speed: 0.75,
    requestRate: 0.8,
    scoreMultiplier: 1,
  },
  {
    id: "sonnet",
    name: "Sonnet",
    blurb: "The everyday driver",
    speed: 1.0,
    requestRate: 1.0,
    scoreMultiplier: 2,
  },
  {
    id: "opus",
    name: "Opus",
    blurb: "Maximum throughput",
    speed: 1.4,
    requestRate: 1.35,
    scoreMultiplier: 3,
  },
]

let mono = "'JetBrains Mono', ui-monospace, monospace"
let wordFont = `600 19px ${mono}`
let chipPadding = 10.0

let measure = (ctx, text) => ctx->Text.width(~font=wordFont, text) +. chipPadding *. 2.0

let background = (ctx, ~width, ~height, ~time as _) => {
  ctx->fillStyle("#0b0d10")
  ctx->fillRect(0.0, 0.0, width, height)
  ctx->fillStyle("rgba(177, 169, 255, 0.07)")
  let step = 24.0
  let y = ref(step)
  while y.contents < height {
    let x = ref(step)
    while x.contents < width {
      ctx->fillRect(x.contents, y.contents, 1.0, 1.0)
      x := x.contents +. step
    }
    y := y.contents +. step
  }
}

let drawWord = (ctx, word: Engine.word, ~input, ~missed, ~time as _) => {
  let top = word.y -. Stage.chipHeight
  ctx->beginPath
  ctx->roundRect(word.x, top, word.width, Stage.chipHeight, 8.0)
  ctx->fillStyle("rgba(28, 32, 36, 0.92)")
  ctx->fill
  let targeted = Engine.isPrefix(input, word.text)
  ctx->lineWidth(1.0)
  ctx->strokeStyle(missed ? Palette.danger : targeted ? Palette.accentBright : Palette.border)
  ctx->stroke
  ctx->font(wordFont)
  ctx->textBaseline("middle")
  if targeted {
    ctx->shadowColor(Palette.accent)
    ctx->shadowBlur(12.0)
  }
  ctx
  ->Text.split(
    ~text=word.text,
    ~input,
    ~x=word.x +. chipPadding,
    ~y=top +. Stage.chipHeight /. 2.0 +. 1.0,
    ~color=Palette.ink,
    ~matchColor=Palette.accentBright,
  )
  ->ignore
  ctx->shadowBlur(0.0)
}

let drawShield = (ctx, shield: Shield.t, ~y) => {
  let size = Shield.cellWidth(shield)
  shield.cells->Array.forEachWithIndex((intact, i) => {
    let x = Int.toFloat(i) *. size
    if intact {
      ctx->fillStyle(Palette.accent)
      ctx->fillRect(x +. 1.0, y +. 4.0, size -. 2.0, 8.0)
      ctx->fillStyle(Palette.accentBright)
      ctx->fillRect(x +. 1.0, y +. 4.0, size -. 2.0, 1.5)
    } else {
      ctx->fillStyle("#3b1a1d")
      ctx->fillRect(x +. 1.0, y +. 8.0, size -. 2.0, 4.0)
    }
  })
}

let monogram = Lazy.make(() => path2d(Glyphs.monogram))
let circuitBoard = Lazy.make(() => path2d(Glyphs.circuitBoard))

let (tileW, tileH) = (104.0, 46.0)

let drawGateway = (ctx, bonus: Engine.bonus, ~time as _) => {
  ctx->shadowColor(Palette.accentBright)
  ctx->shadowBlur(24.0)
  ctx->beginPath
  ctx->roundRect(0.0, 0.0, tileW, tileH, 10.0)
  ctx->fillStyle(Palette.surface)
  ctx->fill
  ctx->shadowBlur(0.0)
  let sheen = ctx->conicGradient(bonus.age *. 2.0, tileW /. 2.0, tileH /. 2.0)
  Palette.iridescent->Array.forEach(((stop, color)) => sheen->addColorStop(stop, color))
  ctx->globalAlpha(0.28)
  ctx->fillGradient(sheen)
  ctx->fill
  ctx->globalAlpha(1.0)
  ctx->lineWidth(1.0)
  ctx->strokeGradient(sheen)
  ctx->stroke
  ctx->save
  ctx->translate(14.0, (tileH -. Glyphs.monogramHeight *. 1.3) /. 2.0)
  ctx->scale(1.3, 1.3)
  ctx->fillGradient(sheen)
  ctx->fillPath(Lazy.get(monogram))
  ctx->restore
  ctx->save
  ctx->translate(60.0, 9.0)
  ctx->scale(1.15, 1.15)
  ctx->strokeStyle(Palette.accentBright)
  ctx->lineWidth(1.8)
  ctx->lineCap("round")
  ctx->lineJoin("round")
  ctx->strokePath(Lazy.get(circuitBoard))
  ctx->restore
}

let gateway: Theme.bonus = {
  spec: {
    word: "gateway",
    label: "Unified Gateway",
    kind: ClearAll,
    chancePerSecond: 0.04,
    minElapsed: 20.0,
    speed: 140.0,
  },
  caption: "UNIFIED GATEWAY",
  cheer: "one credential, every resource",
  width: tileW,
  height: tileH,
  draw: drawGateway,
}

let makeBackdrop = (~width, ~height, ~window) => {
  let board = Circuit.make(~width, ~height, ~window, ~random=Math.random)
  {
    Theme.update: dt => board->Circuit.update(dt),
    draw: (ctx, ~time) => board->Circuit.draw(ctx, ~time),
    capture: (~x, ~y) => board->Circuit.exchange(~x, ~y, ~count=5),
    bonus: _ => board->Circuit.exchangeAll,
  }
}

let sound: Theme.sound = {
  capture: () =>
    Synth.play(ctx => {
      ctx->Synth.tone(
        ~kind="square",
        ~from=660.0,
        ~to_=1760.0,
        ~at=0.0,
        ~duration=0.09,
        ~volume=0.05,
      )
      ctx->Synth.tone(
        ~kind="sine",
        ~from=1320.0,
        ~to_=2640.0,
        ~at=0.06,
        ~duration=0.12,
        ~volume=0.06,
      )
    }),
  miss: () =>
    Synth.play(ctx =>
      ctx->Synth.tone(
        ~kind="sawtooth",
        ~from=180.0,
        ~to_=90.0,
        ~at=0.0,
        ~duration=0.18,
        ~volume=0.05,
      )
    ),
  breach: () =>
    Synth.play(ctx => {
      ctx->Synth.noise(~duration=0.5, ~volume=0.22, ~from=1800.0, ~to_=120.0)
      ctx->Synth.tone(~kind="square", ~from=140.0, ~to_=40.0, ~at=0.0, ~duration=0.35, ~volume=0.06)
    }),
  bonus: _ =>
    Synth.play(ctx =>
      [523.25, 659.25, 783.99, 1046.5, 1318.5]->Array.forEachWithIndex((f, i) =>
        ctx->Synth.tone(
          ~kind="triangle",
          ~from=f,
          ~to_=f *. 1.01,
          ~at=Int.toFloat(i) *. 0.07,
          ~duration=0.35,
          ~volume=0.07,
        )
      )
    ),
}

let theme: Theme.t = {
  id: "keycard",
  name: "Keycard",
  className: "theme-keycard",
  logo: <span className="logo-tile" role="img" ariaLabel="Keycard">
    <span className="logo-mark" />
  </span>,
  copy: {
    appName: "agentically-typed",
    crumb: "token exchange",
    title: "Agentically Typed",
    intro: <>
      <p className="overlay__copy">
        {"Your agents need resources, fast. Type each one as it falls to exchange a token before it breaches your trust boundary."->React.string}
      </p>
      <p className="overlay__copy">
        {"When the "->React.string}
        <strong> {"unified gateway"->React.string} </strong>
        {" drifts by, type "->React.string}
        <code> {"gateway"->React.string} </code>
        {". One credential, every resource."->React.string}
      </p>
    </>,
    baseLabel: "Trust boundary",
    capturesLabel: "Tokens",
    tierLabel: "Model",
    overHeading: "Trust boundary breached",
    overSummary: (~captures, ~score) =>
      `${Int.toString(captures)} tokens exchanged · score ${Int.toString(score)}`,
    log: {
      title: "Audit log",
      subject: "Resource",
      granted: "Granted",
      denied: "Denied",
      empty: "No token exchanges yet.",
    },
    captured: "token issued",
    missed: "403 denied",
    breached: "breach",
    wasted: "unauthorized",
  },
  vocabulary,
  bonuses: [gateway],
  tiers,
  defaultTier: "sonnet",
  look: {
    labelFont: mono,
    bonusFont: `700 17px ${mono}`,
    ink: Palette.ink,
    inkMuted: Palette.inkMuted,
    match: Palette.success,
    captureTint: Palette.success,
    missTint: Palette.danger,
    bonusTint: Palette.accentBright,
    sparks: Palette.pulseColors,
    background,
    word: drawWord,
    measure,
    base: drawShield,
    makeBackdrop,
  },
  sound,
}
