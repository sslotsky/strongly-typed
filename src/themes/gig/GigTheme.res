// The Gig: tune titles drift down like a set list; play each one before it
// hits the stage. Every tune you call plays the next note of a sax line.
open Canvas2d

let vocabulary = [
  "Salt Creek",
  "Blackberry Blossom",
  "Whiskey Before Breakfast",
  "Bill Cheatham",
  "Old Joe Clark",
  "Big Sciota",
  "Freylekhs",
  "Hava Nagila",
  "Odessa Bulgar",
  "Der Heyser Bulgar",
  "Nigun",
  "Doina",
  "Body and Soul",
  "Autumn Leaves",
  "All the Things You Are",
  "Stella by Starlight",
  "Take the A Train",
  "Blue Bossa",
  "Footprints",
  "Moanin'",
  "Giant Steps",
  "Lullaby of Birdland",
  "Bye Bye Blackbird",
  "In a Sentimental Mood",
  "St. Thomas",
  "Cherokee",
  "Solar",
  "Nardis",
]

let tiers: array<Tier.t> = [
  {
    id: "ballad",
    name: "Ballad",
    blurb: "Brushes and candlelight",
    speed: 0.75,
    requestRate: 0.8,
    scoreMultiplier: 1,
  },
  {
    id: "medium",
    name: "Medium Swing",
    blurb: "Right in the pocket",
    speed: 1.0,
    requestRate: 1.0,
    scoreMultiplier: 2,
  },
  {
    id: "burnin",
    name: "Burnin'",
    blurb: "Count it off fast",
    speed: 1.4,
    requestRate: 1.35,
    scoreMultiplier: 3,
  },
]

let ink = "#f7ecd9"
let inkMuted = "#b8a48c"
let amber = "#ffb347"
let brass = "#d9a441"
let teal = "#6fd3c4"
let red = "#ff5d5d"
let sparks = ["#ffb347", "#d9a441", "#f7ecd9", "#6fd3c4", "#ff7a59"]
let serif = "Fraunces, Georgia, serif"
let wordFont = `italic 600 18px ${serif}`
let padding = 14.0

let measure = (ctx, text) => ctx->Text.width(~font=wordFont, text) +. padding *. 2.0 +. 12.0

let background = (ctx, ~width, ~height, ~time) => {
  let wall = ctx->linearGradient(0.0, 0.0, 0.0, height)
  wall->addColorStop(0.0, "#1a1022")
  wall->addColorStop(1.0, "#2a1418")
  ctx->fillGradient(wall)
  ctx->fillRect(0.0, 0.0, width, height)
  // A slow-moving spot on the bandstand.
  let sx = width *. (0.5 +. 0.3 *. Math.sin(time *. 0.4))
  let spot = ctx->radialGradient(sx, height, 0.0, sx, height, height *. 0.9)
  spot->addColorStop(0.0, "rgba(255, 179, 71, 0.16)")
  spot->addColorStop(1.0, "rgba(255, 179, 71, 0)")
  ctx->fillGradient(spot)
  ctx->fillRect(0.0, 0.0, width, height)
}

// An eighth note, centered on its head.
let eighth = (ctx, ~x, ~y, ~size, ~color) => {
  ctx->fillStyle(color)
  ctx->save
  ctx->translate(x, y)
  ctx->rotate(-0.35)
  ctx->scale(size *. 0.55, size *. 0.4)
  ctx->circle(0.0, 0.0, 1.0)
  ctx->restore
  ctx->fill
  ctx->fillRect(x +. size *. 0.42, y -. size *. 1.6, size *. 0.14, size *. 1.6)
  ctx->beginPath
  ctx->moveTo(x +. size *. 0.56, y -. size *. 1.6)
  ctx->lineTo(x +. size *. 1.1, y -. size *. 1.0)
  ctx->lineTo(x +. size *. 0.56, y -. size *. 1.2)
  ctx->fill
}

let drawWord = (ctx, word: Engine.word, ~input, ~missed, ~time) => {
  let cx = word.x +. word.width /. 2.0
  let cy = word.y -. Stage.chipHeight /. 2.0
  let bob = Math.sin(time *. 2.2 +. Int.toFloat(word.id)) *. 1.5
  ctx->save
  ctx->translate(cx, cy +. bob)
  ctx->beginPath
  ctx->roundRect(-.word.width /. 2.0, -.Stage.chipHeight /. 2.0, word.width, Stage.chipHeight, 6.0)
  ctx->fillStyle("#2b1b2e")
  ctx->fill
  let targeted = Engine.isPrefix(input, word.text)
  ctx->lineWidth(missed || targeted ? 2.0 : 1.0)
  ctx->strokeStyle(missed ? red : targeted ? amber : "rgba(217, 164, 65, 0.55)")
  ctx->stroke
  ctx->eighth(~x=-.word.width /. 2.0 +. padding, ~y=5.0, ~size=6.0, ~color=brass)
  ctx->font(wordFont)
  ctx->textBaseline("middle")
  ctx
  ->Text.split(
    ~text=word.text,
    ~input,
    ~x=-.word.width /. 2.0 +. padding +. 12.0,
    ~y=1.0,
    ~color=ink,
    ~matchColor=amber,
  )
  ->ignore
  ctx->restore
}

// Footlights along the front of the stage; a crash blows a bulb.
let drawFootlights = (ctx, shield: Shield.t, ~y) => {
  let size = Shield.cellWidth(shield)
  ctx->fillStyle("#120a14")
  ctx->fillRect(0.0, y +. 4.0, size *. Int.toFloat(Array.length(shield.cells)), 10.0)
  shield.cells->Array.forEachWithIndex((lit, i) => {
    let x = Int.toFloat(i) *. size +. size /. 2.0
    if lit {
      let glow = ctx->radialGradient(x, y +. 6.0, 0.0, x, y +. 6.0, size)
      glow->addColorStop(0.0, "rgba(255, 179, 71, 0.45)")
      glow->addColorStop(1.0, "rgba(255, 179, 71, 0)")
      ctx->fillGradient(glow)
      ctx->fillRect(x -. size, y -. 6.0, size *. 2.0, 22.0)
      ctx->fillStyle("#ffe2a8")
    } else {
      ctx->fillStyle("#3a2a2a")
    }
    ctx->circle(x, y +. 8.0, Math.min(3.5, size *. 0.3))
    ctx->fill
  })
}

// Sprites, drawn with their top-left at the origin.
let horn = (ctx, ~x, ~y, ~tilt) => {
  ctx->save
  ctx->translate(x, y)
  ctx->rotate(tilt)
  ctx->fillStyle(brass)
  ctx->fillRect(0.0, -2.0, 22.0, 4.0)
  ctx->beginPath
  ctx->moveTo(20.0, -2.0)
  ctx->lineTo(30.0, -9.0)
  ctx->lineTo(30.0, 9.0)
  ctx->lineTo(20.0, 2.0)
  ctx->fill
  ctx->fillStyle("#f2d48a")
  ctx->fillRect(6.0, -5.0, 2.5, 4.0)
  ctx->fillRect(10.0, -5.0, 2.5, 4.0)
  ctx->fillRect(14.0, -5.0, 2.5, 4.0)
  ctx->restore
}

let drawHorns = (ctx, bonus: Engine.bonus, ~time as _) =>
  [0.0, 1.0, 2.0]->Array.forEach(i =>
    ctx->horn(
      ~x=8.0 +. i *. 14.0,
      ~y=12.0 +. i *. 11.0,
      ~tilt=-0.25 +. 0.15 *. Math.sin(bonus.age *. 8.0 +. i),
    )
  )

let drawFermata = (ctx, bonus: Engine.bonus, ~time as _) => {
  let pulse = 1.0 +. 0.08 *. Math.sin(bonus.age *. 4.0)
  ctx->save
  ctx->translate(40.0, 30.0)
  ctx->scale(pulse, pulse)
  ctx->strokeStyle(teal)
  ctx->lineWidth(5.0)
  ctx->lineCap("round")
  ctx->beginPath
  ctx->arc(0.0, 0.0, 20.0, Math.Constants.pi, tau)
  ctx->stroke
  ctx->fillStyle(teal)
  ctx->circle(0.0, -4.0, 4.5)
  ctx->fill
  ctx->restore
}

let drawMetronome = (ctx, bonus: Engine.bonus, ~time as _) => {
  ctx->fillStyle("#8a4b2a")
  ctx->beginPath
  ctx->moveTo(28.0, 2.0)
  ctx->lineTo(52.0, 2.0)
  ctx->lineTo(62.0, 44.0)
  ctx->lineTo(18.0, 44.0)
  ctx->fill
  ctx->fillStyle("#f2d48a")
  ctx->fillRect(22.0, 34.0, 36.0, 10.0)
  let swing = Math.sin(bonus.age *. 9.0) *. 0.5
  ctx->save
  ctx->translate(40.0, 36.0)
  ctx->rotate(swing)
  ctx->fillStyle(ink)
  ctx->fillRect(-1.5, -32.0, 3.0, 32.0)
  ctx->fillRect(-4.0, -24.0, 8.0, 5.0)
  ctx->restore
}

let drawRose = (ctx, bonus: Engine.bonus, ~time as _) => {
  ctx->save
  ctx->translate(40.0, 23.0)
  ctx->rotate(bonus.age *. 3.0)
  ctx->strokeStyle("#3f7a3a")
  ctx->lineWidth(3.0)
  ctx->beginPath
  ctx->moveTo(0.0, 0.0)
  ctx->lineTo(0.0, 22.0)
  ctx->stroke
  [0.0, 1.0, 2.0, 3.0, 4.0]->Array.forEach(i => {
    ctx->fillStyle(mod(Float.toInt(i), 2) == 0 ? "#c8243a" : "#e2405a")
    ctx->circle(Math.cos(i *. 1.26) *. 5.0, Math.sin(i *. 1.26) *. 5.0 -. 4.0, 7.0)
    ctx->fill
  })
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
    ~word="horn section",
    ~label="Horn section",
    ~kind=ClearAll,
    ~chance=0.035,
    ~minElapsed=25.0,
    ~speed=120.0,
    ~caption="PLAYS EVERY TUNE",
    ~cheer="shout chorus!",
    ~draw=drawHorns,
  ),
  bonus(
    ~word="fermata",
    ~label="Fermata",
    ~kind=SlowTime(6.0),
    ~chance=0.03,
    ~minElapsed=12.0,
    ~speed=140.0,
    ~caption="HOLDS THE NOTE",
    ~cheer="hold it...",
    ~draw=drawFermata,
  ),
  bonus(
    ~word="double time",
    ~label="Double time",
    ~kind=DoublePoints(8.0),
    ~chance=0.03,
    ~minElapsed=15.0,
    ~speed=170.0,
    ~caption="DOUBLE POINTS",
    ~cheer="double time",
    ~draw=drawMetronome,
  ),
  bonus(
    ~word="encore",
    ~label="Encore",
    ~kind=Repair(6),
    ~chance=0.03,
    ~minElapsed=18.0,
    ~speed=190.0,
    ~caption="RELIGHTS THE STAGE",
    ~cheer="encore!",
    ~draw=drawRose,
  ),
]

// The club: a brick wall, a couple of spots, and notes rising off the stand.
type note = {mutable nx: float, mutable ny: float, mutable nage: float, drift: float, size: float}

let makeClub = (~width, ~height, ~window as _: Dom2.rect): Theme.backdrop => {
  let notes = ref([])
  let flash = ref(0.0)
  let release = (~x, ~y, ~size) =>
    notes :=
      notes.contents->Array.concat([
        {nx: x, ny: y, nage: 0.0, drift: Math.random() *. 50.0 -. 25.0, size},
      ])
  {
    update: dt => {
      flash := Math.max(0.0, flash.contents -. dt)
      notes.contents->Array.forEach(n => {
        n.nage = n.nage +. dt
        n.ny = n.ny -. 45.0 *. dt
        n.nx = n.nx +. n.drift *. dt
      })
      notes := notes.contents->Array.filter(n => n.nage < 3.0)
    },
    draw: (ctx, ~time) => {
      let wall = ctx->linearGradient(0.0, 0.0, 0.0, height)
      wall->addColorStop(0.0, "#170d16")
      wall->addColorStop(1.0, "#2a1210")
      ctx->fillGradient(wall)
      ctx->fillRect(0.0, 0.0, width, height)
      // Mortar lines.
      ctx->strokeStyle("rgba(255, 220, 190, 0.05)")
      ctx->lineWidth(1.0)
      ctx->beginPath
      let row = ref(0)
      let y = ref(0.0)
      while y.contents < height {
        ctx->moveTo(0.0, y.contents)
        ctx->lineTo(width, y.contents)
        let x = ref(mod(row.contents, 2) == 0 ? 0.0 : 26.0)
        while x.contents < width {
          ctx->moveTo(x.contents, y.contents)
          ctx->lineTo(x.contents, y.contents +. 24.0)
          x := x.contents +. 52.0
        }
        y := y.contents +. 24.0
        row := row.contents + 1
      }
      ctx->stroke
      // Spots sweeping from the rig.
      ctx->composite("lighter")
      [0.18, 0.82]->Array.forEachWithIndex((anchor, i) => {
        let ax = width *. anchor
        let sway = Math.sin(time *. 0.5 +. Int.toFloat(i) *. 2.0) *. width *. 0.12
        let beam = ctx->linearGradient(ax, 0.0, ax, height)
        beam->addColorStop(
          0.0,
          `rgba(255, 190, 110, ${Float.toString(0.16 +. flash.contents *. 0.2)})`,
        )
        beam->addColorStop(1.0, "rgba(255, 190, 110, 0)")
        ctx->fillGradient(beam)
        ctx->beginPath
        ctx->moveTo(ax -. 10.0, 0.0)
        ctx->lineTo(ax +. 10.0, 0.0)
        ctx->lineTo(ax +. sway +. width *. 0.14, height)
        ctx->lineTo(ax +. sway -. width *. 0.14, height)
        ctx->closePath
        ctx->fill
      })
      ctx->composite("source-over")
      notes.contents->Array.forEach(n => {
        ctx->globalAlpha(Math.max(0.0, 1.0 -. n.nage /. 3.0))
        ctx->eighth(~x=n.nx, ~y=n.ny, ~size=n.size, ~color=amber)
      })
      ctx->globalAlpha(1.0)
    },
    capture: (~x, ~y) => release(~x, ~y, ~size=9.0),
    bonus: _ => {
      flash := 1.0
      for _ in 1 to 24 {
        release(~x=Math.random() *. width, ~y=height *. (0.6 +. Math.random() *. 0.4), ~size=12.0)
      }
    },
  }
}

// An F blues scale; each tune you call plays the next note of the line.
let scale = [65, 68, 70, 71, 72, 75, 77, 80, 82, 83, 84]
let cursor = ref(4)

let nextNote = () => {
  let step = Float.toInt(Math.random() *. 5.0) - 2
  cursor := Math.Int.max(0, Math.Int.min(Array.length(scale) - 1, cursor.contents + step))
  scale->Array.getUnsafe(cursor.contents)
}

// A breathy reed: a short scoop up into the note.
let reed = (ctx, ~note, ~at=0.0, ~duration=0.32, ~volume=0.07) => {
  let freq = Synth.midi(note)
  ctx->Synth.tone(
    ~kind="sawtooth",
    ~from=freq *. 0.94,
    ~to_=freq,
    ~at,
    ~duration,
    ~volume=volume *. 0.5,
  )
  ctx->Synth.tone(~kind="triangle", ~from=freq *. 0.94, ~to_=freq, ~at, ~duration, ~volume)
}

let sound: Theme.sound = {
  capture: () => Synth.play(ctx => ctx->reed(~note=nextNote())),
  miss: () =>
    // A clam: a squeak a half step off.
    Synth.play(ctx =>
      ctx->Synth.tone(
        ~kind="square",
        ~from=Synth.midi(scale->Array.getUnsafe(cursor.contents) + 13),
        ~to_=Synth.midi(scale->Array.getUnsafe(cursor.contents) + 12),
        ~at=0.0,
        ~duration=0.14,
        ~volume=0.04,
      )
    ),
  breach: () =>
    Synth.play(ctx =>
      ctx->Synth.tone(
        ~kind="sawtooth",
        ~from=130.0,
        ~to_=70.0,
        ~at=0.0,
        ~duration=0.5,
        ~volume=0.06,
      )
    ),
  bonus: _ =>
    Synth.play(ctx =>
      [0, 2, 4, 6, 8, 10]->Array.forEachWithIndex((degree, i) =>
        ctx->reed(~note=scale->Array.getUnsafe(degree), ~at=Int.toFloat(i) *. 0.07, ~duration=0.2)
      )
    ),
}

let theme: Theme.t = {
  id: "gig",
  name: "The Gig",
  className: "theme-gig",
  logo: <svg className="gig-logo" viewBox="0 0 24 24" ariaHidden=true>
    <path d="M9 3h10v3H12v10.5A3.5 3.5 0 1 1 9 13V3z" fill="#ffb347" />
  </svg>,
  copy: {
    appName: "strongly-typed",
    crumb: "the gig",
    title: "The Gig",
    intro: <>
      <p className="overlay__copy">
        {"The set list is coming down from the rafters. Type a tune's title to call it before it hits the stage. Every tune you call plays the next note of your solo."->React.string}
      </p>
      <p className="overlay__copy">
        {"When the "->React.string}
        <strong> {"horn section"->React.string} </strong>
        {" swings by, type it to play the whole set. Listen for a "->React.string}
        <strong> {"fermata"->React.string} </strong>
        {", "->React.string}
        <strong> {"double time"->React.string} </strong>
        {" and an "->React.string}
        <strong> {"encore"->React.string} </strong>
        {" too."->React.string}
      </p>
    </>,
    baseLabel: "Stage",
    capturesLabel: "Played",
    tierLabel: "Tempo",
    overHeading: "The lights went out",
    overSummary: (~captures, ~score) =>
      `${Int.toString(captures)} tunes played · score ${Int.toString(score)}`,
    log: {
      title: "Set list",
      subject: "Tune",
      granted: "Played",
      denied: "Clams",
      empty: "Nothing played yet.",
    },
    captured: "played",
    missed: "clam",
    breached: "blown bulb",
    wasted: "dropped",
  },
  vocabulary,
  bonuses,
  tiers,
  defaultTier: "medium",
  look: {
    labelFont: serif,
    bonusFont: `italic 700 18px ${serif}`,
    ink,
    inkMuted,
    match: amber,
    captureTint: amber,
    missTint: red,
    bonusTint: teal,
    sparks,
    background,
    word: drawWord,
    measure,
    base: drawFootlights,
    makeBackdrop: makeClub,
  },
  sound,
}
