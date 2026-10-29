// Pollinator Lawn's playfield life. Every planted word drops a seed that is
// pulled into the soil, watered and sprouts, so a good run grows a meadow.
// Around it: coneflowers with bees, a feeder with cardinals, a rabbit, a
// squirrel that scolds typos and a deer that wanders through now and then.
open Canvas2d

type seed = {sx: float, mutable sy: float, mutable vy: float, mutable landed: float}
type sprout = {px: float, mutable grow: float, tall: float, lean: float, bloom: option<string>}
type wilt = {wx: float, mutable wt: float}

let petals = ["#c792ea", "#ffd166", "#fdf3e1", "#f4a259", "#e2574c"]
let stemGreen = "#7fae45"
let leafGreen = "#9cc85a"
let serif = "Fraunces, Georgia, serif"
let maxSprouts = 48
let waterTime = 0.9
let scoldTime = 1.6

let pick = arr => arr->Array.getUnsafe(Float.toInt(Math.random() *. Int.toFloat(Array.length(arr))))

let coneflower = (ctx, ~x, ~ground, ~tall, ~time) => {
  let sway = Math.sin(time *. 0.9 +. x) *. 3.0
  let top = ground -. tall
  ctx->strokeStyle(stemGreen)
  ctx->lineWidth(2.0)
  ctx->beginPath
  ctx->moveTo(x, ground)
  ctx->quadraticCurveTo(x +. sway *. 0.3, ground -. tall *. 0.5, x +. sway, top)
  ctx->stroke
  ctx->fillStyle("#c792ea")
  for i in 0 to 8 {
    let a = Int.toFloat(i) /. 9.0 *. tau
    let px = x +. sway +. Math.cos(a) *. 7.0
    let py = top +. 2.0 +. Math.abs(Math.sin(a)) *. 4.0
    ctx->oval(px, py, 6.0, 2.2, a)
    ctx->fill
  }
  ctx->fillStyle("#d9772b")
  ctx->circle(x +. sway, top, 4.0)
  ctx->fill
}

let bee = (ctx, ~x, ~y, ~time) => {
  let flap = 1.5 +. Math.abs(Math.sin(time *. 40.0)) *. 2.0
  ctx->fillStyle("rgba(255, 255, 255, 0.7)")
  ctx->oval(x -. 1.5, y -. 3.5, 3.0, flap, -0.4)
  ctx->fill
  ctx->oval(x +. 1.5, y -. 3.5, 3.0, flap, 0.4)
  ctx->fill
  ctx->fillStyle("#ffd166")
  ctx->oval(x, y, 4.5, 3.0, 0.0)
  ctx->fill
  ctx->fillStyle("#2b1d12")
  ctx->fillRect(x -. 0.8, y -. 3.0, 1.6, 6.0)
}

let cardinal = (ctx, ~x, ~y, ~facing) => {
  ctx->save
  ctx->translate(x, y)
  ctx->scale(facing, 1.0)
  ctx->fillStyle("#c8242c")
  ctx->oval(0.0, 0.0, 7.0, 5.5, 0.0)
  ctx->fill
  ctx->circle(5.0, -5.0, 3.8)
  ctx->fill
  ctx->beginPath
  ctx->moveTo(3.0, -8.0)
  ctx->lineTo(4.5, -13.0)
  ctx->lineTo(7.5, -7.5)
  ctx->closePath
  ctx->fill
  ctx->beginPath
  ctx->moveTo(-6.0, 0.0)
  ctx->lineTo(-14.0, 4.0)
  ctx->lineTo(-6.0, 3.5)
  ctx->closePath
  ctx->fill
  ctx->fillStyle("#f4a259")
  ctx->beginPath
  ctx->moveTo(8.5, -5.8)
  ctx->lineTo(12.0, -4.6)
  ctx->lineTo(8.5, -3.4)
  ctx->closePath
  ctx->fill
  ctx->fillStyle("#1b1410")
  ctx->circle(6.4, -5.4, 1.1)
  ctx->fill
  ctx->restore
}

let feeder = (ctx, ~x, ~ground, ~time) => {
  let top = ground -. 170.0
  ctx->strokeStyle("#3b2a1e")
  ctx->lineWidth(3.0)
  ctx->beginPath
  ctx->moveTo(x, ground)
  ctx->lineTo(x, top)
  ctx->lineTo(x -. 34.0, top)
  ctx->lineTo(x -. 34.0, top +. 6.0)
  ctx->stroke
  ctx->fillStyle("#7a4a22")
  ctx->beginPath
  ctx->moveTo(x -. 52.0, top +. 18.0)
  ctx->lineTo(x -. 34.0, top +. 5.0)
  ctx->lineTo(x -. 16.0, top +. 18.0)
  ctx->closePath
  ctx->fill
  ctx->fillStyle("rgba(232, 214, 176, 0.8)")
  ctx->fillRect(x -. 46.0, top +. 18.0, 24.0, 22.0)
  ctx->fillStyle("#a8743a")
  ctx->fillRect(x -. 46.0, top +. 31.0, 24.0, 9.0)
  ctx->strokeStyle("#7a4a22")
  ctx->beginPath
  ctx->moveTo(x -. 54.0, top +. 41.0)
  ctx->lineTo(x -. 14.0, top +. 41.0)
  ctx->stroke
  // Two cardinals take turns at the feeder.
  [(x -. 50.0, -1.0, 0.0), (x -. 18.0, 1.0, 4.1)]->Array.forEach(((bx, facing, offset)) =>
    if cycle(time +. offset, 9.0) < 5.5 {
      let peck = Math.sin((time +. offset) *. 7.0) > 0.7 ? 1.5 : 0.0
      ctx->cardinal(~x=bx, ~y=top +. 35.0 +. peck, ~facing)
    }
  )
}

let rabbit = (ctx, ~x, ~ground, ~time) => {
  let nibble = Math.sin(time *. 9.0) > 0.4 ? 1.2 : 0.0
  ctx->fillStyle("#a08566")
  ctx->oval(x, ground -. 9.0, 11.0, 8.0, 0.0)
  ctx->fill
  ctx->circle(x +. 10.0, ground -. 14.0 +. nibble, 5.5)
  ctx->fill
  ctx->oval(x +. 7.5, ground -. 24.0 +. nibble, 2.2, 7.0, -0.2)
  ctx->fill
  ctx->oval(x +. 11.5, ground -. 24.0 +. nibble, 2.2, 7.0, 0.2)
  ctx->fill
  ctx->fillStyle("#fdf3e1")
  ctx->circle(x -. 11.0, ground -. 11.0, 3.0)
  ctx->fill
}

// A deer wanders across the back of the yard every so often.
let deer = (ctx, ~width, ~ground, ~time) => {
  let walk = cycle(time, 50.0)
  if walk < 16.0 {
    let x = lerp(width +. 60.0, -60.0, walk /. 16.0)
    let step = Math.sin(time *. 6.0) *. 5.0
    ctx->fillStyle("#4a3424")
    ctx->strokeStyle("#4a3424")
    ctx->lineWidth(3.0)
    ctx->oval(x, ground -. 46.0, 24.0, 10.0, 0.0)
    ctx->fill
    [(-16.0, step), (-10.0, -.step), (12.0, -.step), (18.0, step)]->Array.forEach(((dx, swing)) => {
      ctx->beginPath
      ctx->moveTo(x +. dx, ground -. 40.0)
      ctx->lineTo(x +. dx +. swing, ground)
      ctx->stroke
    })
    ctx->beginPath
    ctx->moveTo(x -. 18.0, ground -. 50.0)
    ctx->lineTo(x -. 28.0, ground -. 70.0)
    ctx->stroke
    ctx->oval(x -. 32.0, ground -. 72.0, 7.0, 4.0, 0.3)
    ctx->fill
    ctx->oval(x -. 26.0, ground -. 79.0, 2.0, 4.5, 0.6)
    ctx->fill
  }
}

let squirrel = (ctx, ~x, ~ground, ~left, ~time) => {
  ctx->globalAlpha(Math.min(1.0, left /. 0.3))
  let rise = Math.min(1.0, (scoldTime -. left) /. 0.15) *. 26.0
  let y = ground +. 26.0 -. rise
  ctx->fillStyle("#8a6a4a")
  ctx->save
  ctx->translate(x +. 9.0, y -. 8.0)
  ctx->rotate(Math.sin(time *. 30.0) *. 0.25)
  ctx->oval(6.0, -14.0, 7.0, 15.0, 0.3)
  ctx->fill
  ctx->restore
  ctx->oval(x, y -. 10.0, 8.0, 10.0, -0.2)
  ctx->fill
  ctx->circle(x -. 6.0, y -. 22.0, 5.5)
  ctx->fill
  ctx->beginPath
  ctx->moveTo(x -. 6.0, y -. 26.0)
  ctx->lineTo(x -. 3.0, y -. 33.0)
  ctx->lineTo(x -. 1.0, y -. 25.0)
  ctx->closePath
  ctx->fill
  ctx->fillStyle("#1b1410")
  ctx->circle(x -. 8.5, y -. 23.0, 1.2)
  ctx->fill
  ctx->font(`italic 600 13px ${serif}`)
  ctx->textAlign("right")
  ctx->fillStyle("#fdf3e1")
  let chatter = Math.sin(time *. 18.0) > 0.0 ? 0.0 : 1.5
  ctx->fillText("chk-chk-chk!", x -. 14.0, y -. 34.0 -. chatter)
  ctx->textAlign("start")
  ctx->globalAlpha(1.0)
}

let wateringCan = (ctx, ~x, ~y, ~tilt) => {
  ctx->save
  ctx->translate(x, y)
  ctx->rotate(tilt)
  ctx->fillStyle("#6b8fa3")
  ctx->roundRect(-10.0, -8.0, 20.0, 16.0, 3.0)
  ctx->fill
  ctx->strokeStyle("#6b8fa3")
  ctx->lineWidth(3.0)
  ctx->beginPath
  ctx->moveTo(-9.0, 2.0)
  ctx->lineTo(-22.0, -6.0)
  ctx->stroke
  ctx->lineWidth(2.0)
  ctx->beginPath
  ctx->arc(4.0, -8.0, 6.0, Math.Constants.pi, tau)
  ctx->stroke
  ctx->restore
}

let make = (stage: Theme.stage): Theme.scene => {
  let width = stage.width
  let ground = stage.height -. Engine.shieldHeight
  let seeds: ref<array<seed>> = ref([])
  let sprouts: ref<array<sprout>> = ref([])
  let wilts: ref<array<wilt>> = ref([])
  let scold = ref(0.0)

  let plant = (word: Engine.word) =>
    seeds.contents->Array.push({
      sx: Math.max(14.0, Math.min(width -. 14.0, word.x +. word.width /. 2.0)),
      sy: word.y -. 16.0,
      vy: -80.0,
      landed: -1.0,
    })

  let sprout = (seed: seed) => {
    sprouts.contents->Array.push({
      px: seed.sx,
      grow: 0.0,
      tall: 14.0 +. Math.random() *. 18.0,
      lean: (Math.random() -. 0.5) *. 0.4,
      bloom: Math.random() < 0.6 ? Some(pick(petals)) : None,
    })
    if Array.length(sprouts.contents) > maxSprouts {
      sprouts.contents->Array.shift->ignore
    }
  }

  {
    onEvent: event =>
      switch event {
      | Captured(word) => plant(word)
      | BonusCaptured(_, words) => words->Array.forEach(plant)
      | Missed(_) => scold := scoldTime
      | Breached(word, _) => wilts.contents->Array.push({wx: word.x +. word.width /. 2.0, wt: 0.0})
      | Spawned(_) => ()
      },
    update: dt => {
      seeds.contents =
        seeds.contents->Array.filter(seed =>
          if seed.landed < 0.0 {
            seed.vy = seed.vy +. 700.0 *. dt
            seed.sy = seed.sy +. seed.vy *. dt
            if seed.sy >= ground -. 3.0 {
              seed.sy = ground -. 3.0
              seed.landed = 0.0
            }
            true
          } else {
            seed.landed = seed.landed +. dt
            if seed.landed >= waterTime {
              sprout(seed)
              false
            } else {
              true
            }
          }
        )
      sprouts.contents->Array.forEach(s => s.grow = Math.min(1.0, s.grow +. dt /. 1.2))
      wilts.contents =
        wilts.contents->Array.filter(w => {
          w.wt = w.wt +. dt
          w.wt < 3.0
        })
      scold := Math.max(0.0, scold.contents -. dt)
    },
    drawBack: (ctx, ~time) => {
      ctx->globalAlpha(0.35)
      ctx->deer(~width, ~ground, ~time)
      ctx->globalAlpha(0.6)
      let flowers = [(70.0, 56.0), (180.0, 72.0), (300.0, 48.0), (560.0, 64.0), (690.0, 52.0)]
      flowers->Array.forEach(((x, tall)) => ctx->coneflower(~x, ~ground, ~tall, ~time))
      ctx->feeder(~x=width -. 24.0, ~ground, ~time)
      ctx->rabbit(~x=430.0, ~ground, ~time)
      ctx->globalAlpha(0.9)
      flowers->Array.forEachWithIndex(((x, tall), i) => {
        let t = time *. (1.1 +. Int.toFloat(i) *. 0.13) +. Int.toFloat(i) *. 2.0
        ctx->bee(
          ~x=x +. Math.cos(t) *. 20.0,
          ~y=ground -. tall -. 14.0 +. Math.sin(t *. 1.7) *. 9.0,
          ~time,
        )
      })
      ctx->globalAlpha(1.0)
    },
    drawFront: (ctx, ~time) => {
      seeds.contents->Array.forEach(seed => {
        if seed.landed < 0.0 {
          ctx->fillStyle("#7a4a22")
          ctx->oval(seed.sx, seed.sy, 2.6, 4.0, 0.0)
          ctx->fill
        } else {
          let p = seed.landed /. waterTime
          ctx->globalAlpha(1.0 -. p)
          ctx->fillStyle("#7a4a22")
          ctx->oval(seed.sx, seed.sy +. p *. 4.0, 2.6, 4.0, 0.0)
          ctx->fill
          ctx->globalAlpha(Math.min(1.0, (1.0 -. p) *. 4.0))
          ctx->wateringCan(
            ~x=seed.sx +. 26.0,
            ~y=ground -. 40.0,
            ~tilt=-0.6 *. Math.min(1.0, p *. 5.0),
          )
          ctx->fillStyle("#7fc8f8")
          for i in 0 to 4 {
            let fall = cycle(seed.landed *. 2.2 +. Int.toFloat(i) /. 5.0, 1.0)
            ctx->circle(
              seed.sx +. 6.0 -. Int.toFloat(i) *. 1.6,
              ground -. 34.0 +. fall *. 30.0,
              1.4,
            )
            ctx->fill
          }
          ctx->globalAlpha(1.0)
        }
      })
      sprouts.contents->Array.forEach(s => {
        let h = s.tall *. s.grow
        let tipX = s.px +. s.lean *. h
        ctx->strokeStyle(stemGreen)
        ctx->lineWidth(1.8)
        ctx->beginPath
        ctx->moveTo(s.px, ground)
        ctx->quadraticCurveTo(s.px +. s.lean *. h *. 0.3, ground -. h *. 0.5, tipX, ground -. h)
        ctx->stroke
        if s.grow > 0.3 {
          let g = s.grow
          ctx->fillStyle(leafGreen)
          ctx->oval(s.px -. 4.0 *. g, ground -. h *. 0.45, 4.5 *. g, 2.0 *. g, -0.6)
          ctx->fill
          ctx->oval(s.px +. 4.0 *. g, ground -. h *. 0.65, 4.5 *. g, 2.0 *. g, 0.6)
          ctx->fill
        }
        switch s.bloom {
        | Some(color) if s.grow >= 1.0 =>
          ctx->fillStyle(color)
          ctx->circle(tipX, ground -. h, 3.2)
          ctx->fill
          ctx->fillStyle("#d9772b")
          ctx->circle(tipX, ground -. h, 1.2)
          ctx->fill
        | _ => ()
        }
      })
      wilts.contents->Array.forEach(w => {
        let curl = Math.min(1.0, w.wt /. 0.8)
        ctx->globalAlpha(1.0 -. w.wt /. 3.0)
        ctx->fillStyle("#6b4a2a")
        ctx->oval(w.wx, ground -. 3.0, 8.0 *. (1.0 -. curl *. 0.45), 3.2, curl *. 0.9)
        ctx->fill
        ctx->globalAlpha(1.0)
      })
      if scold.contents > 0.0 {
        ctx->squirrel(~x=width -. 70.0, ~ground, ~left=scold.contents, ~time)
      }
    },
  }
}
