// Pollinator Lawn: autumn leaves carry native seeds; sow each before it lands.
open Canvas2d

let vocabulary = [
  "goldenrod",
  "little bluestem",
  "bee balm",
  "aster",
  "milkweed",
  "prairie dropseed",
  "coneflower",
  "black-eyed Susan",
  "wild bergamot",
  "blazing star",
  "joe-pye weed",
  "switchgrass",
  "columbine",
  "wild geranium",
  "anise hyssop",
  "mountain mint",
  "foxglove beardtongue",
  "sideoats grama",
  "lupine",
  "rattlesnake master",
  "ironweed",
  "creeping thyme",
  "white clover",
  "self-heal",
  "violet",
  "sedge",
  "spiderwort",
  "boneset",
]

let tiers: array<Tier.t> = [
  {
    id: "breeze",
    name: "Breeze",
    blurb: "A slow drift of leaves",
    speed: 0.75,
    requestRate: 0.8,
    scoreMultiplier: 1,
  },
  {
    id: "gust",
    name: "Gust",
    blurb: "Peak color, peak wind",
    speed: 1.0,
    requestRate: 1.0,
    scoreMultiplier: 2,
  },
  {
    id: "gale",
    name: "Gale",
    blurb: "Hold onto your hat",
    speed: 1.4,
    requestRate: 1.35,
    scoreMultiplier: 3,
  },
]

let ink = "#fdf3e1"
let inkMuted = "#c9b49a"
let gold = "#ffd166"
let meadow = "#9cc85a"
let crimson = "#e2574c"
let leafColors = ["#a8442a", "#b5562b", "#8f2f24", "#9a6a1f", "#7a4a22"]
let sparks = ["#ffd166", "#f4a259", "#e2574c", "#9cc85a", "#fdf3e1"]
let serif = "Fraunces, Georgia, serif"
let wordFont = `600 18px ${serif}`
let padding = 14.0

let measure = (ctx, text) => ctx->Text.width(~font=wordFont, text) +. padding *. 2.0 +. 10.0

let background = (ctx, ~width, ~height, ~time) => {
  let sky = ctx->linearGradient(0.0, 0.0, 0.0, height)
  sky->addColorStop(0.0, "#1a1220")
  sky->addColorStop(1.0, "#2b1a12")
  ctx->fillGradient(sky)
  ctx->fillRect(0.0, 0.0, width, height)
  // Fireflies.
  ctx->composite("lighter")
  for i in 0 to 22 {
    let f = Int.toFloat(i)
    let x = Float.mod(f *. 137.0 +. time *. (6.0 +. Float.mod(f, 5.0)), width)
    let y = height *. 0.15 +. Float.mod(f *. 71.0, height *. 0.7) +. 8.0 *. Math.sin(time +. f)
    let glow = 0.25 +. 0.25 *. Math.sin(time *. 2.0 +. f *. 1.7)
    ctx->globalAlpha(Math.max(0.0, glow))
    ctx->fillStyle(gold)
    ctx->circle(x, y, 1.6)
    ctx->fill
  }
  ctx->globalAlpha(1.0)
  ctx->composite("source-over")
}

let leafPath = (ctx, x, y, size) => {
  ctx->beginPath
  ctx->moveTo(x, y -. size)
  ctx->lineTo(x +. size *. 0.55, y)
  ctx->lineTo(x, y +. size)
  ctx->lineTo(x -. size *. 0.55, y)
  ctx->closePath
}

let drawWord = (ctx, word: Engine.word, ~input, ~missed, ~time) => {
  let color = leafColors->Array.getUnsafe(mod(word.id, Array.length(leafColors)))
  let cx = word.x +. word.width /. 2.0
  let cy = word.y -. Stage.chipHeight /. 2.0
  let sway = Math.sin(time *. 1.6 +. Int.toFloat(word.id)) *. 0.06
  ctx->save
  ctx->translate(cx, cy)
  ctx->rotate(sway)
  ctx->beginPath
  ctx->roundRect(-.word.width /. 2.0, -.Stage.chipHeight /. 2.0, word.width, Stage.chipHeight, 16.0)
  ctx->fillStyle(color)
  ctx->fill
  let targeted = Engine.isPrefix(input, word.text)
  ctx->lineWidth(missed || targeted ? 2.0 : 1.0)
  ctx->strokeStyle(missed ? crimson : targeted ? gold : "rgba(253, 243, 225, 0.25)")
  ctx->stroke
  // A little leaf on the tag.
  ctx->fillStyle("rgba(253, 243, 225, 0.85)")
  ctx->leafPath(-.word.width /. 2.0 +. padding, 0.0, 6.0)
  ctx->fill
  ctx->font(wordFont)
  ctx->textBaseline("middle")
  ctx
  ->Text.split(
    ~text=word.text,
    ~input,
    ~x=-.word.width /. 2.0 +. padding +. 10.0,
    ~y=1.0,
    ~color=ink,
    ~matchColor=gold,
  )
  ->ignore
  ctx->restore
}

let flowerColors = ["#c792ea", "#ffd166", "#fdf3e1", "#f4a259"]

let drawLawn = (ctx, shield: Shield.t, ~y) => {
  let size = Shield.cellWidth(shield)
  shield.cells->Array.forEachWithIndex((intact, i) => {
    let x = Int.toFloat(i) *. size
    if intact {
      ctx->fillStyle("#3f6b2a")
      ctx->fillRect(x, y +. 6.0, size, 8.0)
      ctx->strokeStyle(meadow)
      ctx->lineWidth(1.2)
      for b in 0 to 3 {
        let bx = x +. 2.0 +. Int.toFloat(b) *. (size -. 4.0) /. 3.0
        ctx->beginPath
        ctx->moveTo(bx, y +. 8.0)
        ctx->lineTo(bx +. (mod(i + b, 2) == 0 ? 2.0 : -2.0), y -. 2.0)
        ctx->stroke
      }
      if mod(i * 7, 5) == 0 {
        ctx->fillStyle(flowerColors->Array.getUnsafe(mod(i, Array.length(flowerColors))))
        ctx->circle(x +. size /. 2.0, y -. 2.0, 2.2)
        ctx->fill
      }
    } else {
      ctx->fillStyle("#4a3326")
      ctx->fillRect(x, y +. 8.0, size, 6.0)
      ctx->fillStyle("#6b4c3a")
      ctx->circle(x +. size *. 0.3, y +. 10.0, 1.2)
      ctx->fill
    }
  })
}

// Sprites, drawn with their top-left at the origin.
let wing = (ctx, ~x, ~y, ~rx, ~ry, ~angle, ~color) => {
  ctx->save
  ctx->translate(x, y)
  ctx->rotate(angle)
  ctx->scale(rx, ry)
  ctx->circle(0.0, 0.0, 1.0)
  ctx->restore
  ctx->fillStyle(color)
  ctx->fill
}

let drawMonarch = (ctx, bonus: Engine.bonus, ~time as _) => {
  let flap = 0.35 +. 0.65 *. Math.abs(Math.sin(bonus.age *. 9.0))
  ctx->save
  ctx->translate(40.0, 24.0)
  ctx->scale(flap, 1.0)
  ctx->strokeStyle("#1a1210")
  ctx->lineWidth(2.0)
  [-1.0, 1.0]->Array.forEach(side => {
    ctx->wing(~x=side *. 16.0, ~y=-6.0, ~rx=17.0, ~ry=13.0, ~angle=side *. -0.5, ~color="#e8762b")
    ctx->stroke
    ctx->wing(~x=side *. 12.0, ~y=11.0, ~rx=11.0, ~ry=9.0, ~angle=side *. 0.4, ~color="#d0611f")
    ctx->stroke
    ctx->fillStyle("#fdf3e1")
    ctx->circle(side *. 26.0, -10.0, 1.6)
    ctx->fill
    ctx->circle(side *. 20.0, 16.0, 1.4)
    ctx->fill
  })
  ctx->restore
  ctx->fillStyle("#1a1210")
  ctx->beginPath
  ctx->roundRect(38.0, 8.0, 4.0, 30.0, 2.0)
  ctx->fill
}

let drawBee = (ctx, bonus: Engine.bonus, ~time as _) => {
  ctx->globalAlpha(0.7)
  let buzz = Math.sin(bonus.age *. 40.0) *. 3.0
  ctx->wing(~x=26.0, ~y=8.0 +. buzz, ~rx=10.0, ~ry=6.0, ~angle=-0.4, ~color="#e8f1ff")
  ctx->wing(~x=36.0, ~y=8.0 -. buzz, ~rx=10.0, ~ry=6.0, ~angle=0.4, ~color="#e8f1ff")
  ctx->globalAlpha(1.0)
  ctx->save
  ctx->translate(32.0, 24.0)
  ctx->scale(20.0, 13.0)
  ctx->circle(0.0, 0.0, 1.0)
  ctx->restore
  ctx->fillStyle("#f2b632")
  ctx->fill
  ctx->fillStyle("#1a1210")
  [22.0, 32.0, 42.0]->Array.forEach(x => ctx->fillRect(x -. 2.5, 13.0, 5.0, 22.0))
}

let drawCardinal = (ctx, _bonus: Engine.bonus, ~time as _) => {
  ctx->fillStyle("#c8102e")
  ctx->save
  ctx->translate(30.0, 26.0)
  ctx->scale(20.0, 14.0)
  ctx->circle(0.0, 0.0, 1.0)
  ctx->restore
  ctx->fill
  ctx->circle(48.0, 16.0, 9.0)
  ctx->fill
  // Crest, tail, beak and mask.
  ctx->beginPath
  ctx->moveTo(44.0, 9.0)
  ctx->lineTo(50.0, -2.0)
  ctx->lineTo(54.0, 10.0)
  ctx->fill
  ctx->beginPath
  ctx->moveTo(12.0, 24.0)
  ctx->lineTo(-4.0, 34.0)
  ctx->lineTo(12.0, 32.0)
  ctx->fill
  ctx->fillStyle("#1a1210")
  ctx->circle(51.0, 17.0, 3.5)
  ctx->fill
  ctx->fillStyle("#f4a259")
  ctx->beginPath
  ctx->moveTo(55.0, 14.0)
  ctx->lineTo(64.0, 18.0)
  ctx->lineTo(55.0, 21.0)
  ctx->fill
}

let drawRabbit = (ctx, bonus: Engine.bonus, ~time as _) => {
  let hop = Math.abs(Math.sin(bonus.age *. 5.0)) *. -8.0
  ctx->save
  ctx->translate(0.0, hop)
  ctx->fillStyle("#9b8b7e")
  ctx->save
  ctx->translate(28.0, 30.0)
  ctx->scale(18.0, 12.0)
  ctx->circle(0.0, 0.0, 1.0)
  ctx->restore
  ctx->fill
  ctx->circle(46.0, 22.0, 8.0)
  ctx->fill
  ctx->save
  ctx->translate(46.0, 8.0)
  ctx->scale(3.0, 9.0)
  ctx->circle(0.0, 0.0, 1.0)
  ctx->restore
  ctx->fill
  ctx->fillStyle("#fdf3e1")
  ctx->circle(10.0, 28.0, 4.5)
  ctx->fill
  ctx->fillStyle("#1a1210")
  ctx->circle(49.0, 20.0, 1.5)
  ctx->fill
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
    ~word="monarch",
    ~label="Monarch",
    ~kind=ClearAll,
    ~chance=0.035,
    ~minElapsed=25.0,
    ~speed=120.0,
    ~caption="POLLINATES EVERYTHING",
    ~cheer="pollinated!",
    ~draw=drawMonarch,
  ),
  bonus(
    ~word="bumblebee",
    ~label="Bumblebee",
    ~kind=SlowTime(6.0),
    ~chance=0.03,
    ~minElapsed=12.0,
    ~speed=150.0,
    ~caption="SLOWS THE WIND",
    ~cheer="the wind settles",
    ~draw=drawBee,
  ),
  bonus(
    ~word="cardinal",
    ~label="Cardinal",
    ~kind=DoublePoints(8.0),
    ~chance=0.03,
    ~minElapsed=15.0,
    ~speed=170.0,
    ~caption="DOUBLE POINTS",
    ~cheer="double points",
    ~draw=drawCardinal,
  ),
  bonus(
    ~word="rabbit",
    ~label="Rabbit",
    ~kind=Repair(6),
    ~chance=0.03,
    ~minElapsed=18.0,
    ~speed=190.0,
    ~caption="REGROWS THE LAWN",
    ~cheer="the lawn grows back",
    ~draw=drawRabbit,
  ),
]

// A tune in D major pentatonic: each sown seed plays the next note.
let scale = [62, 64, 66, 69, 71, 74, 76, 78, 81, 83]
let cursor = ref(4)

let nextNote = () => {
  let step = Float.toInt(Math.random() *. 5.0) - 2
  cursor := Math.Int.max(0, Math.Int.min(Array.length(scale) - 1, cursor.contents + step))
  scale->Array.getUnsafe(cursor.contents)
}

let sound: Theme.sound = {
  capture: () => Synth.play(ctx => ctx->Synth.pluck(~freq=Synth.midi(nextNote()))),
  miss: () =>
    // A clam: a semitone off the tune, cut short.
    Synth.play(ctx =>
      ctx->Synth.pluck(
        ~freq=Synth.midi(scale->Array.getUnsafe(cursor.contents) + 1),
        ~duration=0.25,
        ~cents=25.0,
      )
    ),
  breach: () =>
    Synth.play(ctx =>
      ctx->Synth.tone(~kind="sine", ~from=110.0, ~to_=45.0, ~at=0.0, ~duration=0.35, ~volume=0.12)
    ),
  bonus: _ =>
    Synth.play(ctx =>
      [0, 2, 4, 5, 7, 9]->Array.forEachWithIndex((degree, i) =>
        ctx->Synth.pluck(
          ~freq=Synth.midi(scale->Array.getUnsafe(degree)),
          ~at=Int.toFloat(i) *. 0.08,
          ~volume=0.07,
        )
      )
    ),
}

let theme: Theme.t = {
  id: "garden",
  name: "Pollinator Lawn",
  className: "theme-garden",
  logo: <svg className="garden-logo" viewBox="0 0 24 24" ariaHidden=true>
    <path
      d="M12 2c3 3 7 4 9 3-1 4-3 6-5 7 2 1 3 2 4 4-3 0-5-1-6-2l-1 8h-2l-1-8c-1 1-3 2-6 2 1-2 2-3 4-4-2-1-4-3-5-7 2 1 6 0 9-3z"
      fill="#e07a2f"
    />
  </svg>,
  favicon: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="5" fill="#241a14"/><path d="M12 2c3 3 7 4 9 3-1 4-3 6-5 7 2 1 3 2 4 4-3 0-5-1-6-2l-1 8h-2l-1-8c-1 1-3 2-6 2 1-2 2-3 4-4-2-1-4-3-5-7 2 1 6 0 9-3z" fill="#e07a2f" transform="translate(2.4 2.4) scale(.8)"/></svg>`,
  copy: {
    appName: "strongly-typed",
    crumb: "pollinator lawn",
    title: "Pollinator Lawn",
    intro: <>
      <p className="overlay__copy">
        {"Autumn leaves are falling, each one carrying a native seed. Type a plant's name to sow it before it lands. Every seed you sow plays the next note of the tune."->React.string}
      </p>
      <p className="overlay__copy">
        {"When the "->React.string}
        <strong> {"monarch"->React.string} </strong>
        {" drifts by, type it to pollinate everything. Watch for the "->React.string}
        <strong> {"bumblebee"->React.string} </strong>
        {", "->React.string}
        <strong> {"cardinal"->React.string} </strong>
        {" and "->React.string}
        <strong> {"rabbit"->React.string} </strong>
        {" too."->React.string}
      </p>
    </>,
    baseLabel: "Lawn",
    capturesLabel: "Sown",
    tierLabel: "Wind",
    overHeading: "The lawn went bare",
    overSummary: (~captures, ~score) =>
      `${Int.toString(captures)} seeds sown · score ${Int.toString(score)}`,
    log: {
      title: "Field notes",
      subject: "Plant",
      granted: "Sown",
      denied: "Missed",
      empty: "Nothing sown yet.",
    },
    captured: "sown",
    missed: "missed",
    breached: "bare patch",
    wasted: "trampled",
  },
  vocabulary,
  bonuses,
  tiers,
  defaultTier: "gust",
  look: {
    labelFont: serif,
    bonusFont: `700 18px ${serif}`,
    ink,
    inkMuted,
    match: gold,
    captureTint: meadow,
    missTint: crimson,
    bonusTint: gold,
    sparks,
    background,
    word: drawWord,
    measure,
    base: drawLawn,
    makeBackdrop: (~width, ~height, ~window) => Yard.make(~width, ~height, ~window),
    makeScene: GardenScene.make,
  },
  sound,
}
