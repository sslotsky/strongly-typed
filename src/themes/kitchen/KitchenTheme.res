// Low & Slow: order tickets come off the rail; fire each one before it hits
// the pass. The smoker, the bread oven and the stockpot are all going.
open Canvas2d

let vocabulary = [
  "brisket",
  "burnt ends",
  "pulled pork",
  "spare ribs",
  "pork belly",
  "pastrami",
  "smoked turkey",
  "beef tallow",
  "country loaf",
  "focaccia",
  "baguette",
  "rye",
  "ciabatta",
  "bagels",
  "levain",
  "brioche",
  "chicken stock",
  "bone broth",
  "chili",
  "gumbo",
  "jambalaya",
  "short ribs",
  "cornbread",
  "collard greens",
  "mac and cheese",
  "coleslaw",
  "pickles",
  "smoked salmon",
]

let tiers: array<Tier.t> = [
  {
    id: "simmer",
    name: "Simmer",
    blurb: "A quiet Tuesday",
    speed: 0.75,
    requestRate: 0.8,
    scoreMultiplier: 1,
  },
  {
    id: "sear",
    name: "Sear",
    blurb: "Friday night",
    speed: 1.0,
    requestRate: 1.0,
    scoreMultiplier: 2,
  },
  {
    id: "rush",
    name: "Dinner Rush",
    blurb: "Everything, all at once",
    speed: 1.4,
    requestRate: 1.35,
    scoreMultiplier: 3,
  },
]

let ink = "#f6ead7"
let inkMuted = "#b9a58c"
let ember = "#ff8a3d"
let paper = "#f3e9d6"
let ticketInk = "#2b2118"
let char = "#c0392b"
let herb = "#8cc56a"
let sparks = ["#ff8a3d", "#ffc15e", "#f6ead7", "#c0392b", "#8cc56a"]
let mono = "'JetBrains Mono', ui-monospace, monospace"
let wordFont = `700 16px ${mono}`
let padding = 12.0

let measure = (ctx, text) => ctx->Text.width(~font=wordFont, text) +. padding *. 2.0

let background = (ctx, ~width, ~height, ~time as _) => {
  let wall = ctx->linearGradient(0.0, 0.0, 0.0, height)
  wall->addColorStop(0.0, "#1c1714")
  wall->addColorStop(1.0, "#2c1d14")
  ctx->fillGradient(wall)
  ctx->fillRect(0.0, 0.0, width, height)
  let heat = ctx->radialGradient(width /. 2.0, height, 0.0, width /. 2.0, height, height *. 0.8)
  heat->addColorStop(0.0, "rgba(255, 138, 61, 0.14)")
  heat->addColorStop(1.0, "rgba(255, 138, 61, 0)")
  ctx->fillGradient(heat)
  ctx->fillRect(0.0, 0.0, width, height)
}

let drawWord = (ctx, word: Engine.word, ~input, ~missed, ~time) => {
  let cx = word.x +. word.width /. 2.0
  let cy = word.y -. Stage.chipHeight /. 2.0
  let flutter = Math.sin(time *. 3.0 +. Int.toFloat(word.id)) *. 0.03
  ctx->save
  ctx->translate(cx, cy)
  ctx->rotate(flutter)
  let left = -.word.width /. 2.0
  let top = -.Stage.chipHeight /. 2.0
  ctx->beginPath
  ctx->roundRect(left, top, word.width, Stage.chipHeight, 3.0)
  ctx->fillStyle(paper)
  ctx->fill
  let targeted = Engine.isPrefix(input, word.text)
  ctx->fillStyle(missed ? char : targeted ? ember : "#7a6a58")
  ctx->fillRect(left, top, word.width, 4.0)
  if missed || targeted {
    ctx->lineWidth(2.0)
    ctx->strokeStyle(missed ? char : ember)
    ctx->stroke
  }
  ctx->font(wordFont)
  ctx->textBaseline("middle")
  ctx
  ->Text.split(
    ~text=word.text,
    ~input,
    ~x=left +. padding,
    ~y=2.0,
    ~color=ticketInk,
    ~matchColor=char,
  )
  ->ignore
  ctx->restore
}

// The coal bed: each crash leaves a patch of cold ash.
let drawCoals = (ctx, shield: Shield.t, ~y) => {
  let size = Shield.cellWidth(shield)
  ctx->fillStyle("#1a1210")
  ctx->fillRect(0.0, y +. 4.0, size *. Int.toFloat(Array.length(shield.cells)), 10.0)
  shield.cells->Array.forEachWithIndex((hot, i) => {
    let x = Int.toFloat(i) *. size
    if hot {
      let glow = ctx->linearGradient(0.0, y, 0.0, y +. 14.0)
      glow->addColorStop(0.0, "#ffc15e")
      glow->addColorStop(1.0, "#b8401c")
      ctx->fillGradient(glow)
      ctx->beginPath
      ctx->roundRect(x +. 1.0, y +. 4.0, size -. 2.0, 9.0, 4.0)
      ctx->fill
    } else {
      ctx->fillStyle("#4b4441")
      ctx->beginPath
      ctx->roundRect(x +. 1.0, y +. 7.0, size -. 2.0, 6.0, 3.0)
      ctx->fill
    }
  })
}

// Sprites, drawn with their top-left at the origin.
let drawStarter = (ctx, bonus: Engine.bonus, ~time as _) => {
  ctx->fillStyle("rgba(220, 235, 240, 0.35)")
  ctx->beginPath
  ctx->roundRect(22.0, 10.0, 36.0, 36.0, 6.0)
  ctx->fill
  ctx->fillStyle("#efe2c4")
  ctx->beginPath
  ctx->roundRect(24.0, 20.0, 32.0, 24.0, 4.0)
  ctx->fill
  // Bubbling over the rim.
  for i in 0 to 5 {
    let f = Int.toFloat(i)
    let rise = Float.mod(bonus.age *. 1.5 +. f *. 0.37, 1.0)
    ctx->fillStyle("#efe2c4")
    ctx->circle(26.0 +. f *. 6.0, 12.0 -. rise *. 10.0, 4.0 +. Float.mod(f, 2.0) *. 2.0)
    ctx->fill
  }
  ctx->strokeStyle("rgba(43, 33, 24, 0.4)")
  ctx->lineWidth(1.0)
  [26.0, 34.0, 44.0]->Array.forEach(x => {
    ctx->circle(x, 32.0, 1.6)
    ctx->stroke
  })
}

let drawBanneton = (ctx, bonus: Engine.bonus, ~time as _) => {
  let rise = 1.0 +. 0.06 *. Math.sin(bonus.age *. 2.0)
  ctx->save
  ctx->translate(40.0, 26.0)
  ctx->scale(rise, rise)
  ctx->fillStyle("#a8743f")
  ctx->circle(0.0, 0.0, 20.0)
  ctx->fill
  ctx->strokeStyle("#6e4521")
  ctx->lineWidth(1.5)
  [6.0, 11.0, 16.0]->Array.forEach(r => {
    ctx->circle(0.0, 0.0, r)
    ctx->stroke
  })
  ctx->restore
}

let drawBrisket = (ctx, _bonus: Engine.bonus, ~time as _) => {
  ctx->fillStyle("#2a140c")
  ctx->beginPath
  ctx->roundRect(8.0, 14.0, 64.0, 24.0, 10.0)
  ctx->fill
  ctx->fillStyle("#d9826a")
  ctx->fillRect(62.0, 17.0, 6.0, 18.0)
  ctx->fillStyle("#c0392b")
  ctx->fillRect(60.0, 17.0, 2.0, 18.0)
  ctx->fillStyle("rgba(255, 193, 94, 0.5)")
  [18.0, 30.0, 42.0, 52.0]->Array.forEach(x => {
    ctx->circle(x, 22.0, 1.4)
    ctx->fill
  })
}

let drawLogs = (ctx, bonus: Engine.bonus, ~time as _) => {
  let lick = Math.sin(bonus.age *. 12.0) *. 3.0
  ctx->fillStyle(ember)
  ctx->beginPath
  ctx->moveTo(24.0, 30.0)
  ctx->lineTo(40.0 +. lick, 2.0)
  ctx->lineTo(56.0, 30.0)
  ctx->fill
  ctx->fillStyle("#ffc15e")
  ctx->beginPath
  ctx->moveTo(32.0, 30.0)
  ctx->lineTo(40.0 -. lick, 14.0)
  ctx->lineTo(48.0, 30.0)
  ctx->fill
  ctx->fillStyle("#6e4521")
  ctx->save
  ctx->translate(40.0, 36.0)
  ctx->rotate(0.25)
  ctx->fillRect(-28.0, -5.0, 56.0, 10.0)
  ctx->rotate(-0.5)
  ctx->fillRect(-28.0, -5.0, 56.0, 10.0)
  ctx->restore
}

let bonus = (
  ~word,
  ~label,
  ~kind,
  ~chance,
  ~minElapsed,
  ~speed,
  ~caption,
  ~cheer,
  ~draw,
): Theme.bonus => {
  spec: {word, label, kind, chancePerSecond: chance, minElapsed, speed},
  caption,
  cheer,
  width: 80.0,
  height: 46.0,
  draw,
}

let bonuses = [
  bonus(
    ~word="starter",
    ~label="Starter",
    ~kind=ClearAll,
    ~chance=0.035,
    ~minElapsed=25.0,
    ~speed=110.0,
    ~caption="FIRES EVERY ORDER",
    ~cheer="it bubbled over!",
    ~draw=drawStarter,
  ),
  bonus(
    ~word="proof",
    ~label="Proof",
    ~kind=SlowTime(6.0),
    ~chance=0.03,
    ~minElapsed=12.0,
    ~speed=140.0,
    ~caption="SLOWS THE RAIL",
    ~cheer="let it rest",
    ~draw=drawBanneton,
  ),
  bonus(
    ~word="bark",
    ~label="Bark",
    ~kind=DoublePoints(8.0),
    ~chance=0.03,
    ~minElapsed=15.0,
    ~speed=170.0,
    ~caption="DOUBLE POINTS",
    ~cheer="beautiful bark",
    ~draw=drawBrisket,
  ),
  bonus(
    ~word="stoke",
    ~label="Stoke",
    ~kind=Repair(6),
    ~chance=0.03,
    ~minElapsed=18.0,
    ~speed=190.0,
    ~caption="RELIGHTS THE COALS",
    ~cheer="the coals catch",
    ~draw=drawLogs,
  ),
]

// The smokehouse wall behind the window: smoke curls up all night.
type puff = {mutable px: float, mutable py: float, mutable page: float, drift: float, life: float}

let makeSmokehouse = (~width, ~height, ~window: Dom2.rect): Theme.backdrop => {
  let puffs = ref([])
  let embers = ref([])
  let emit = ref(0.0)
  let add = (~x, ~y, ~life) =>
    puffs :=
      puffs.contents->Array.concat([
        {px: x, py: y, page: 0.0, drift: Math.random() *. 30.0 -. 15.0, life},
      ])
  let spark = (~x, ~y) =>
    embers :=
      embers.contents->Array.concat([
        {px: x, py: y, page: 0.0, drift: Math.random() *. 80.0 -. 40.0, life: 1.2},
      ])
  {
    update: dt => {
      emit := emit.contents +. dt
      if emit.contents > 0.25 {
        emit := 0.0
        let side =
          Math.random() < 0.5
            ? window.left *. Math.random()
            : window.right +. (width -. window.right) *. Math.random()
        add(~x=side, ~y=height +. 20.0, ~life=7.0)
      }
      let step = (p: puff, rise) => {
        p.page = p.page +. dt
        p.py = p.py -. rise *. dt
        p.px = p.px +. p.drift *. dt
      }
      puffs.contents->Array.forEach(p => step(p, 40.0))
      embers.contents->Array.forEach(p => step(p, 90.0))
      puffs := puffs.contents->Array.filter(p => p.page < p.life)
      embers := embers.contents->Array.filter(p => p.page < p.life)
    },
    draw: (ctx, ~time) => {
      let wall = ctx->linearGradient(0.0, 0.0, 0.0, height)
      wall->addColorStop(0.0, "#141110")
      wall->addColorStop(1.0, "#2a1a10")
      ctx->fillGradient(wall)
      ctx->fillRect(0.0, 0.0, width, height)
      // Hanging rail of tickets along the top.
      ctx->fillStyle("#6b6259")
      ctx->fillRect(0.0, 18.0, width, 4.0)
      let x = ref(20.0)
      let i = ref(0)
      while x.contents < width {
        let sway = Math.sin(time *. 1.2 +. Int.toFloat(i.contents)) *. 0.05
        ctx->save
        ctx->translate(x.contents, 22.0)
        ctx->rotate(sway)
        ctx->fillStyle("rgba(243, 233, 214, 0.12)")
        ctx->fillRect(-12.0, 0.0, 24.0, 34.0)
        ctx->restore
        x := x.contents +. 64.0
        i := i.contents + 1
      }
      puffs.contents->Array.forEach(p => {
        let t = p.page /. p.life
        ctx->globalAlpha(0.05 *. Math.sin(t *. Math.Constants.pi))
        ctx->fillStyle("#d9d2c8")
        ctx->circle(p.px +. 12.0 *. Math.sin(p.page *. 1.3), p.py, 18.0 +. t *. 50.0)
        ctx->fill
      })
      ctx->composite("lighter")
      embers.contents->Array.forEach(p => {
        ctx->globalAlpha(Math.max(0.0, 1.0 -. p.page /. p.life))
        ctx->fillStyle(ember)
        ctx->circle(p.px, p.py, 1.8)
        ctx->fill
      })
      ctx->composite("source-over")
      ctx->globalAlpha(1.0)
    },
    capture: (~x, ~y) => {
      add(~x, ~y, ~life=3.0)
      for _ in 1 to 6 {
        spark(~x, ~y)
      }
    },
    bonus: _ =>
      for _ in 1 to 30 {
        let x = Math.random() *. width
        spark(~x, ~y=height)
        add(~x, ~y=height, ~life=5.0)
      },
  }
}

let sound: Theme.sound = {
  // Order up: a quick sizzle and the pass bell.
  capture: () =>
    Synth.play(ctx => {
      ctx->Synth.noise(~duration=0.12, ~volume=0.05, ~from=4000.0, ~to_=2000.0)
      ctx->Synth.tone(
        ~kind="sine",
        ~from=1760.0,
        ~to_=1760.0,
        ~at=0.02,
        ~duration=0.35,
        ~volume=0.06,
      )
      ctx->Synth.tone(
        ~kind="sine",
        ~from=2640.0,
        ~to_=2640.0,
        ~at=0.02,
        ~duration=0.2,
        ~volume=0.02,
      )
    }),
  miss: () =>
    // A dropped pan.
    Synth.play(ctx =>
      ctx->Synth.tone(
        ~kind="square",
        ~from=220.0,
        ~to_=140.0,
        ~at=0.0,
        ~duration=0.15,
        ~volume=0.04,
      )
    ),
  breach: () =>
    Synth.play(ctx => ctx->Synth.noise(~duration=0.6, ~volume=0.08, ~from=900.0, ~to_=200.0)),
  bonus: _ =>
    Synth.play(ctx =>
      [0.0, 0.12, 0.24]->Array.forEach(at =>
        ctx->Synth.tone(~kind="sine", ~from=1760.0, ~to_=1760.0, ~at, ~duration=0.3, ~volume=0.05)
      )
    ),
}

let theme: Theme.t = {
  id: "kitchen",
  name: "Low & Slow",
  className: "theme-kitchen",
  logo: <svg className="kitchen-logo" viewBox="0 0 24 24" ariaHidden=true>
    <path
      d="M12 2c1 3 4 4 4 8a4 4 0 0 1-8 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-4 0-7zM4 16h16v2a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4v-2z"
      fill="#ff8a3d"
    />
  </svg>,
  favicon: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="5" fill="#1f1512"/><path d="M12 2c1 3 4 4 4 8a4 4 0 0 1-8 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-4 0-7zM4 16h16v2a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4v-2z" fill="#ff8a3d" transform="translate(2.4 2.4) scale(.8)"/></svg>`,
  copy: {
    appName: "strongly-typed",
    crumb: "low & slow",
    title: "Low & Slow",
    intro: <>
      <p className="overlay__copy">
        {"Tickets are coming off the rail. Type each order to fire it before it hits the pass and the coals go cold."->React.string}
      </p>
      <p className="overlay__copy">
        {"When the sourdough "->React.string}
        <strong> {"starter"->React.string} </strong>
        {" bubbles over, type it to fire every order. Keep an eye out for "->React.string}
        <strong> {"proof"->React.string} </strong>
        {", "->React.string}
        <strong> {"bark"->React.string} </strong>
        {" and "->React.string}
        <strong> {"stoke"->React.string} </strong>
        {" too."->React.string}
      </p>
    </>,
    baseLabel: "Coals",
    capturesLabel: "Fired",
    tierLabel: "Heat",
    overHeading: "The fire went out",
    overSummary: (~captures, ~score) =>
      `${Int.toString(captures)} orders fired · score ${Int.toString(score)}`,
    log: {
      title: "Ticket rail",
      subject: "Order",
      granted: "Fired",
      denied: "Burnt",
      empty: "No orders fired yet.",
    },
    captured: "fired",
    missed: "burnt",
    breached: "cold coals",
    wasted: "86'd",
  },
  vocabulary,
  bonuses,
  tiers,
  defaultTier: "sear",
  look: {
    labelFont: mono,
    bonusFont: `700 16px ${mono}`,
    ink,
    inkMuted,
    match: ember,
    captureTint: herb,
    missTint: char,
    bonusTint: ember,
    sparks,
    background,
    word: drawWord,
    measure,
    base: drawCoals,
    makeBackdrop: makeSmokehouse,
    makeScene: KitchenScene.make,
  },
  sound,
}
