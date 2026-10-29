// The backyard behind the window at golden hour: sky, hills, trees, falling
// leaves. Sowing a seed sends a pollinator out into the yard.
open Canvas2d

type leaf = {
  mutable lx: float,
  mutable ly: float,
  mutable spin: float,
  drift: float,
  fall: float,
  color: string,
}

type critter = {
  mutable cx: float,
  mutable cy: float,
  vx: float,
  vy: float,
  mutable age: float,
  butterfly: bool,
}

type bloom = {bx: float, by: float, mutable bage: float, petal: string}

let leafColors = ["#c8553d", "#e07a2f", "#f2a541", "#9e2b25", "#b5562b"]
let petals = ["#c792ea", "#ffd166", "#fdf3e1", "#f4a259", "#e2574c"]

let pick = arr => arr->Array.getUnsafe(Float.toInt(Math.random() *. Int.toFloat(Array.length(arr))))

let hill = (ctx, ~width, ~base, ~amplitude, ~phase, ~color) => {
  ctx->beginPath
  ctx->moveTo(0.0, base)
  let x = ref(0.0)
  while x.contents <= width {
    ctx->lineTo(x.contents, base -. amplitude *. Math.sin(x.contents /. 260.0 +. phase))
    x := x.contents +. 20.0
  }
  ctx->lineTo(width, base +. 2000.0)
  ctx->lineTo(0.0, base +. 2000.0)
  ctx->closePath
  ctx->fillStyle(color)
  ctx->fill
}

let tree = (ctx, ~x, ~ground, ~size) => {
  ctx->fillStyle("#2a1a12")
  ctx->fillRect(x -. size *. 0.06, ground -. size, size *. 0.12, size)
  for i in 0 to 7 {
    let f = Int.toFloat(i)
    ctx->fillStyle(leafColors->Array.getUnsafe(mod(i, Array.length(leafColors))))
    ctx->globalAlpha(0.85)
    ctx->circle(
      x +. Math.cos(f *. 2.4) *. size *. 0.32,
      ground -. size -. Math.sin(f *. 1.7) *. size *. 0.22,
      size *. (0.22 +. Float.mod(f, 3.0) *. 0.04),
    )
    ctx->fill
  }
  ctx->globalAlpha(1.0)
}

let make = (~width, ~height, ~window: Dom2.rect): Theme.backdrop => {
  let dpr = Math.min(2.0, Dom2.devicePixelRatio)
  let scenery = offscreen(~width=Float.toInt(width *. dpr), ~height=Float.toInt(height *. dpr))
  let s = scenery->getContext
  s->setTransform(dpr, 0.0, 0.0, dpr, 0.0, 0.0)
  let sky = s->linearGradient(0.0, 0.0, 0.0, height)
  sky->addColorStop(0.0, "#2b1d3a")
  sky->addColorStop(0.45, "#8a3b3a")
  sky->addColorStop(0.75, "#e07a2f")
  sky->addColorStop(1.0, "#f2a541")
  s->fillGradient(sky)
  s->fillRect(0.0, 0.0, width, height)
  let sunY = height *. 0.78
  let sun = s->radialGradient(width *. 0.5, sunY, 0.0, width *. 0.5, sunY, height *. 0.5)
  sun->addColorStop(0.0, "rgba(255, 220, 150, 0.9)")
  sun->addColorStop(1.0, "rgba(255, 220, 150, 0)")
  s->fillGradient(sun)
  s->fillRect(0.0, 0.0, width, height)
  s->hill(~width, ~base=height *. 0.8, ~amplitude=30.0, ~phase=0.0, ~color="#5a3d2b")
  s->hill(~width, ~base=height *. 0.88, ~amplitude=22.0, ~phase=2.0, ~color="#3b2a20")
  let ground = height *. 0.92
  [0.06, 0.14, 0.86, 0.94]->Array.forEachWithIndex((fx, i) =>
    s->tree(~x=width *. fx, ~ground, ~size=height *. (i == 0 || i == 3 ? 0.42 : 0.32))
  )
  s->hill(~width, ~base=height *. 0.95, ~amplitude=10.0, ~phase=4.0, ~color="#2f3d1e")

  let leaves = Array.fromInitializer(~length=40, _ => {
    lx: Math.random() *. width,
    ly: Math.random() *. height,
    spin: Math.random() *. tau,
    drift: 10.0 +. Math.random() *. 30.0,
    fall: 20.0 +. Math.random() *. 40.0,
    color: pick(leafColors),
  })
  let critters: ref<array<critter>> = ref([])
  let blooms: ref<array<bloom>> = ref([])

  let release = (~x, ~y, ~butterfly) => {
    let angle = Math.random() *. tau
    let speed = 90.0 +. Math.random() *. 120.0
    critters :=
      critters.contents->Array.concat([
        {
          cx: x,
          cy: y,
          vx: Math.cos(angle) *. speed,
          vy: Math.sin(angle) *. speed,
          age: 0.0,
          butterfly,
        },
      ])
  }
  let bloomSomewhere = () => {
    let bx = Math.random() *. width
    // Keep blooms out from under the window.
    let bx =
      bx > window.left && bx < window.right
        ? Math.random() < 0.5 ? window.left -. 30.0 : window.right +. 30.0
        : bx
    blooms :=
      blooms.contents->Array.concat([
        {bx, by: height *. (0.94 +. Math.random() *. 0.05), bage: 0.0, petal: pick(petals)},
      ])
  }

  {
    update: dt => {
      leaves->Array.forEach(l => {
        l.ly = l.ly +. l.fall *. dt
        l.lx = l.lx +. Math.sin(l.spin) *. l.drift *. dt
        l.spin = l.spin +. dt
        if l.ly > height {
          l.ly = -10.0
          l.lx = Math.random() *. width
        }
      })
      critters :=
        critters.contents->Array.filter(c => {
          c.age = c.age +. dt
          c.cx = c.cx +. (c.vx +. 40.0 *. Math.sin(c.age *. 6.0)) *. dt
          c.cy = c.cy +. (c.vy +. 30.0 *. Math.cos(c.age *. 5.0)) *. dt
          c.age < 4.0
        })
      blooms.contents->Array.forEach(b => b.bage = b.bage +. dt)
      blooms :=
        blooms.contents->Array.slice(~start=Math.Int.max(0, Array.length(blooms.contents) - 120))
    },
    draw: (ctx, ~time as _) => {
      ctx->setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
      ctx->drawImage(scenery, 0.0, 0.0)
      ctx->setTransform(dpr, 0.0, 0.0, dpr, 0.0, 0.0)
      blooms.contents->Array.forEach(b => {
        let r = Math.min(1.0, b.bage *. 2.0) *. 4.0
        ctx->fillStyle(b.petal)
        ctx->circle(b.bx, b.by, r)
        ctx->fill
        ctx->fillStyle("#ffd166")
        ctx->circle(b.bx, b.by, r *. 0.35)
        ctx->fill
      })
      leaves->Array.forEach(l => {
        ctx->save
        ctx->translate(l.lx, l.ly)
        ctx->rotate(l.spin)
        ctx->scale(1.0, 0.5 +. 0.5 *. Math.abs(Math.sin(l.spin *. 2.0)))
        ctx->fillStyle(l.color)
        ctx->globalAlpha(0.8)
        ctx->beginPath
        ctx->moveTo(0.0, -6.0)
        ctx->lineTo(4.0, 0.0)
        ctx->lineTo(0.0, 6.0)
        ctx->lineTo(-4.0, 0.0)
        ctx->fill
        ctx->restore
      })
      ctx->globalAlpha(1.0)
      critters.contents->Array.forEach(c => {
        let flap = Math.abs(Math.sin(c.age *. 14.0))
        ctx->globalAlpha(Math.min(1.0, 4.0 -. c.age))
        if c.butterfly {
          ctx->fillStyle("#e8762b")
          ctx->save
          ctx->translate(c.cx, c.cy)
          ctx->scale(0.3 +. flap *. 0.7, 1.0)
          ctx->circle(-5.0, 0.0, 5.0)
          ctx->fill
          ctx->circle(5.0, 0.0, 5.0)
          ctx->fill
          ctx->restore
        } else {
          ctx->fillStyle("#f2b632")
          ctx->circle(c.cx, c.cy, 3.5)
          ctx->fill
          ctx->fillStyle("rgba(232, 241, 255, 0.8)")
          ctx->circle(c.cx, c.cy -. 3.0 -. flap *. 2.0, 2.5)
          ctx->fill
        }
      })
      ctx->globalAlpha(1.0)
    },
    capture: (~x, ~y) => {
      release(~x, ~y, ~butterfly=false)
      bloomSomewhere()
    },
    bonus: _ =>
      for _ in 1 to 24 {
        release(
          ~x=window.left +. Math.random() *. (window.right -. window.left),
          ~y=window.top +. Math.random() *. (window.bottom -. window.top),
          ~butterfly=true,
        )
        bloomSomewhere()
      },
  }
}
