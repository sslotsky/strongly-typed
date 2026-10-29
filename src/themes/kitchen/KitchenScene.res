// Low & Slow's line. Filled orders get spiked on the spindle while the plate
// slides down the pass; a typo flares the grill ("BEHIND!") and rattles the
// pans; an order that hits the floor smashes. Around it: the smoker puffing,
// sourdough rising, hanging pans and a stockpot on a simmer.
open Canvas2d

type ticket = {kx: float, ky: float, mutable kt: float, tilt: float}
type plate = {mutable pt: float}
type shard = {
  mutable hx: float,
  mutable hy: float,
  hvx: float,
  mutable hvy: float,
  spin: float,
  mutable hl: float,
}

let paper = "#f3e9d6"
let ticketInk = "#2b2118"
let steel = "#8d8a86"
let mono = "'JetBrains Mono', ui-monospace, monospace"
let spikeTime = 0.5
let slideTime = 1.4
let flareTime = 0.9
let passY = 140.0
let maxSpiked = 16

let sizzle = () =>
  Synth.play(ctx => ctx->Synth.noise(~duration=0.6, ~volume=0.09, ~from=5000.0, ~to_=900.0))

let smash = () =>
  Synth.play(ctx => {
    ctx->Synth.noise(~duration=0.35, ~volume=0.16, ~from=9000.0, ~to_=3000.0)
    ctx->Synth.tone(
      ~kind="triangle",
      ~from=1900.0,
      ~to_=1500.0,
      ~at=0.0,
      ~duration=0.25,
      ~volume=0.03,
    )
  })

let ticketCard = (ctx, ~x, ~y, ~angle) => {
  ctx->save
  ctx->translate(x, y)
  ctx->rotate(angle)
  ctx->fillStyle(paper)
  ctx->fillRect(-13.0, -9.0, 26.0, 18.0)
  ctx->fillStyle(ticketInk)
  ctx->fillRect(-9.0, -5.0, 14.0, 1.5)
  ctx->fillRect(-9.0, -1.0, 18.0, 1.5)
  ctx->fillRect(-9.0, 3.0, 10.0, 1.5)
  ctx->restore
}

let make = (stage: Theme.stage): Theme.scene => {
  let width = stage.width
  let ground = stage.height -. Engine.shieldHeight
  let spindleX = width -. 40.0
  let tickets: ref<array<ticket>> = ref([])
  let spiked: ref<array<float>> = ref([])
  let plates: ref<array<plate>> = ref([])
  let shards: ref<array<shard>> = ref([])
  let flare = ref(0.0)
  let jangle = ref(0.0)

  let serve = (word: Engine.word) => {
    tickets.contents->Array.push({
      kx: word.x +. word.width /. 2.0,
      ky: word.y -. 16.0,
      kt: 0.0,
      tilt: (Math.random() -. 0.5) *. 0.5,
    })
    plates.contents->Array.push({pt: 0.0})
  }

  {
    onEvent: event =>
      switch event {
      | Captured(word) => serve(word)
      | BonusCaptured(_, words) => words->Array.forEach(serve)
      | Missed(_) =>
        flare := flareTime
        jangle := 1.0
        stage.shake(0.25)
        sizzle()
      | Breached(word, _) =>
        let x = word.x +. word.width /. 2.0
        for _ in 1 to 14 {
          shards.contents->Array.push({
            hx: x,
            hy: ground -. 6.0,
            hvx: (Math.random() -. 0.5) *. 260.0,
            hvy: -.(120.0 +. Math.random() *. 220.0),
            spin: (Math.random() -. 0.5) *. 20.0,
            hl: 0.9,
          })
        }
        jangle := 0.6
        stage.shake(0.5)
        smash()
      | Spawned(_) => ()
      },
    update: dt => {
      tickets.contents =
        tickets.contents->Array.filter(t => {
          t.kt = t.kt +. dt
          if t.kt >= spikeTime {
            spiked.contents->Array.push(t.tilt)
            if Array.length(spiked.contents) > maxSpiked {
              spiked.contents->Array.shift->ignore
            }
            false
          } else {
            true
          }
        })
      plates.contents =
        plates.contents->Array.filter(p => {
          p.pt = p.pt +. dt
          p.pt < slideTime
        })
      shards.contents =
        shards.contents->Array.filter(s => {
          s.hx = s.hx +. s.hvx *. dt
          s.hvy = s.hvy +. 900.0 *. dt
          s.hy = Math.min(ground -. 2.0, s.hy +. s.hvy *. dt)
          s.hl = s.hl -. dt
          s.hl > 0.0
        })
      flare := Math.max(0.0, flare.contents -. dt)
      jangle := Math.max(0.0, jangle.contents -. dt *. 0.8)
    },
    drawBack: (ctx, ~time) => {
      ctx->globalAlpha(0.65)
      // Hanging pans on a rail, top left.
      ctx->strokeStyle(steel)
      ctx->lineWidth(3.0)
      ctx->beginPath
      ctx->moveTo(24.0, 16.0)
      ctx->lineTo(200.0, 16.0)
      ctx->stroke
      [(46.0, 14.0), (88.0, 18.0), (134.0, 11.0), (174.0, 15.0)]->Array.forEachWithIndex((
        (x, size),
        i,
      ) => {
        let swing =
          Math.sin(time *. (1.2 +. jangle.contents *. 9.0) +. Int.toFloat(i)) *.
          (0.05 +. jangle.contents *. 0.35)
        ctx->save
        ctx->translate(x, 16.0)
        ctx->rotate(swing)
        ctx->strokeStyle("#5a5450")
        ctx->lineWidth(3.0)
        ctx->beginPath
        ctx->moveTo(0.0, 0.0)
        ctx->lineTo(0.0, size *. 1.6)
        ctx->stroke
        ctx->fillStyle("#3a3634")
        ctx->circle(0.0, size *. 2.6, size)
        ctx->fill
        ctx->strokeStyle("#6a6460")
        ctx->lineWidth(1.5)
        ctx->stroke
        ctx->restore
      })
      // Heat lamps over the pass.
      [260.0, 440.0, 620.0]->Array.forEach(x => {
        ctx->strokeStyle("#3a3634")
        ctx->lineWidth(1.5)
        ctx->beginPath
        ctx->moveTo(x, 0.0)
        ctx->lineTo(x, 100.0)
        ctx->stroke
        ctx->fillStyle("#4a4644")
        ctx->beginPath
        ctx->moveTo(x -. 8.0, 100.0)
        ctx->lineTo(x +. 8.0, 100.0)
        ctx->lineTo(x +. 16.0, 114.0)
        ctx->lineTo(x -. 16.0, 114.0)
        ctx->closePath
        ctx->fill
        let glow = ctx->radialGradient(x, 116.0, 2.0, x, 126.0, 60.0)
        glow->addColorStop(0.0, "rgba(255, 138, 61, 0.35)")
        glow->addColorStop(1.0, "rgba(255, 138, 61, 0)")
        ctx->fillGradient(glow)
        ctx->fillRect(x -. 60.0, 114.0, 120.0, 60.0)
      })
      ctx->fillStyle(steel)
      ctx->fillRect(40.0, passY, width -. 150.0, 5.0)
      // The spindle and the tickets already on it.
      ctx->fillStyle("#5a5450")
      ctx->oval(spindleX, passY, 14.0, 4.0, 0.0)
      ctx->fill
      ctx->strokeStyle(steel)
      ctx->lineWidth(2.0)
      ctx->beginPath
      ctx->moveTo(spindleX, passY)
      ctx->lineTo(spindleX, passY -. 72.0)
      ctx->stroke
      ctx->globalAlpha(0.9)
      spiked.contents->Array.forEachWithIndex((tilt, i) =>
        ctx->ticketCard(~x=spindleX, ~y=passY -. 8.0 -. Int.toFloat(i) *. 3.5, ~angle=tilt)
      )
      ctx->globalAlpha(0.65)
      // The smoker, bottom left, puffing.
      for i in 0 to 6 {
        let ph = cycle(time *. 0.35 +. Int.toFloat(i) /. 7.0, 1.0)
        ctx->fillStyle(`rgba(210, 200, 190, ${Float.toString((1.0 -. ph) *. 0.3)})`)
        ctx->circle(
          35.0 +. Math.sin(ph *. 5.0 +. Int.toFloat(i)) *. 8.0 +. ph *. 22.0,
          ground -. 120.0 -. ph *. 110.0,
          6.0 +. ph *. 16.0,
        )
        ctx->fill
      }
      ctx->fillStyle("#4a3b32")
      ctx->fillRect(30.0, ground -. 120.0, 10.0, 60.0)
      ctx->roundRect(22.0, ground -. 66.0, 112.0, 46.0, 20.0)
      ctx->fill
      ctx->fillRect(134.0, ground -. 54.0, 38.0, 32.0)
      ctx->strokeStyle("#4a3b32")
      ctx->lineWidth(3.0)
      [40.0, 120.0]->Array.forEach(x => {
        ctx->beginPath
        ctx->moveTo(x, ground -. 22.0)
        ctx->lineTo(x, ground)
        ctx->stroke
      })
      ctx->fillStyle(`rgba(255, 138, 61, ${Float.toString(0.4 +. Math.sin(time *. 5.0) *. 0.15)})`)
      ctx->fillRect(140.0, ground -. 34.0, 26.0, 6.0)
      // Stockpot on a simmer.
      let potX = width -. 270.0
      ctx->strokeStyle("rgba(255, 255, 255, 0.35)")
      ctx->lineWidth(2.0)
      for i in 0 to 2 {
        let ph = cycle(time *. 0.5 +. Int.toFloat(i) /. 3.0, 1.0)
        let sx = potX -. 12.0 +. Int.toFloat(i) *. 12.0
        let sy = ground -. 62.0 -. ph *. 50.0
        ctx->globalAlpha((1.0 -. ph) *. 0.6)
        ctx->beginPath
        ctx->moveTo(sx, sy +. 12.0)
        ctx->quadraticCurveTo(sx +. 6.0, sy +. 6.0, sx, sy)
        ctx->quadraticCurveTo(sx -. 6.0, sy -. 6.0, sx, sy -. 12.0)
        ctx->stroke
      }
      ctx->globalAlpha(0.65)
      ctx->fillStyle("#6c6a68")
      ctx->roundRect(potX -. 28.0, ground -. 52.0, 56.0, 46.0, 4.0)
      ctx->fill
      ctx->fillStyle("#8d8a86")
      ctx->fillRect(potX -. 32.0, ground -. 56.0, 64.0, 5.0)
      // Sourdough rising in its banneton.
      let doughX = width -. 150.0
      let rise = 7.0 +. 6.0 *. (0.5 +. 0.5 *. Math.sin(time *. 0.3))
      ctx->fillStyle("#efe0c4")
      ctx->oval(doughX, ground -. 24.0, 26.0, rise, 0.0)
      ctx->fill
      ctx->strokeStyle("#c9a878")
      ctx->lineWidth(1.5)
      ctx->beginPath
      ctx->moveTo(doughX -. 8.0, ground -. 24.0 -. rise *. 0.7)
      ctx->quadraticCurveTo(
        doughX,
        ground -. 26.0 -. rise,
        doughX +. 10.0,
        ground -. 24.0 -. rise *. 0.6,
      )
      ctx->stroke
      ctx->fillStyle("#a8743a")
      ctx->oval(doughX, ground -. 18.0, 32.0, 11.0, 0.0)
      ctx->fill
      ctx->strokeStyle("#7a5228")
      ctx->lineWidth(1.0)
      ctx->oval(doughX, ground -. 18.0, 24.0, 7.0, 0.0)
      ctx->stroke
      ctx->globalAlpha(1.0)
    },
    drawFront: (ctx, ~time) => {
      plates.contents->Array.forEach(p => {
        let q = p.pt /. slideTime
        let x = lerp(56.0, width -. 140.0, 1.0 -. (1.0 -. q) *. (1.0 -. q))
        ctx->globalAlpha(Math.min(1.0, (1.0 -. q) *. 5.0))
        ctx->fillStyle("#f6ead7")
        ctx->oval(x, passY -. 2.0, 18.0, 5.0, 0.0)
        ctx->fill
        ctx->fillStyle("#6b2e1a")
        ctx->oval(x, passY -. 6.0, 10.0, 4.0, 0.0)
        ctx->fill
        ctx->fillStyle("#8cc56a")
        ctx->circle(x +. 9.0, passY -. 6.0, 2.0)
        ctx->fill
      })
      ctx->globalAlpha(1.0)
      tickets.contents->Array.forEach(t => {
        let p = t.kt /. spikeTime
        let x = lerp(t.kx, spindleX, p)
        let y =
          lerp(t.ky, passY -. 8.0 -. Int.toFloat(Array.length(spiked.contents)) *. 3.5, p) -.
          Math.sin(Math.Constants.pi *. p) *. 40.0
        ctx->ticketCard(~x, ~y, ~angle=t.tilt +. (1.0 -. p) *. 6.0)
      })
      shards.contents->Array.forEach(s => {
        ctx->globalAlpha(Math.min(1.0, s.hl *. 2.0))
        ctx->save
        ctx->translate(s.hx, s.hy)
        ctx->rotate(s.spin *. s.hl)
        ctx->fillStyle("#f6ead7")
        ctx->beginPath
        ctx->moveTo(-4.0, -2.0)
        ctx->lineTo(4.0, -3.0)
        ctx->lineTo(1.0, 4.0)
        ctx->closePath
        ctx->fill
        ctx->restore
      })
      ctx->globalAlpha(1.0)
      if flare.contents > 0.0 {
        let p = flare.contents /. flareTime
        for k in 0 to 6 {
          let fk = Int.toFloat(k)
          let x = 138.0 +. fk *. 5.0
          let h = p *. (34.0 +. Math.sin(fk *. 1.7 +. time *. 30.0) *. 12.0)
          ctx->fillStyle(k - k / 2 * 2 == 0 ? "#ff8a3d" : "#ffc15e")
          ctx->beginPath
          ctx->moveTo(x -. 5.0, ground -. 54.0)
          ctx->quadraticCurveTo(x -. 3.0, ground -. 54.0 -. h *. 0.6, x, ground -. 54.0 -. h)
          ctx->quadraticCurveTo(x +. 3.0, ground -. 54.0 -. h *. 0.6, x +. 5.0, ground -. 54.0)
          ctx->closePath
          ctx->fill
        }
        ctx->globalAlpha(Math.min(1.0, p *. 3.0))
        ctx->fillStyle(paper)
        ctx->roundRect(176.0, ground -. 140.0, 86.0, 28.0, 6.0)
        ctx->fill
        ctx->font(`700 15px ${mono}`)
        ctx->fillStyle(ticketInk)
        ctx->fillText("BEHIND!", 186.0, ground -. 121.0)
        ctx->globalAlpha(1.0)
      }
    },
  }
}
