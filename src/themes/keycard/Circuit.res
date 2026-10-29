// The holographic circuit board behind the game window. Traces are routed on a
// grid out of pins on the window's edges; token exchanges send light pulses
// along them (out as a request, back as the issued token).
open Canvas2d

type point = {x: float, y: float}

type trace = {points: array<point>, lengths: array<float>, total: float, fromPin: bool}

type direction = Out | Back

type pulse = {
  trace: int,
  mutable dist: float,
  speed: float,
  dir: direction,
  color: string,
  alpha: float,
}

type flash = {fx: float, fy: float, mutable age: float, color: string}

type t = {
  width: float,
  height: float,
  dpr: float,
  traces: array<trace>,
  mask: element,
  glow: element,
  buffer: element,
  mutable pulses: array<pulse>,
  mutable flashes: array<flash>,
  mutable untilAmbient: float,
}

let grid = 14.0
let maxPulses = 260

let simplify = (points: array<point>) => {
  let n = Array.length(points)
  points->Array.filterWithIndex((p, i) =>
    if i == 0 || i == n - 1 {
      true
    } else {
      let a = points->Array.getUnsafe(i - 1)
      let b = points->Array.getUnsafe(i + 1)
      let (dx1, dy1, dx2, dy2) = (p.x -. a.x, p.y -. a.y, b.x -. p.x, b.y -. p.y)
      Math.abs(dx1 *. dy2 -. dy1 *. dx2) > 0.01
    }
  )
}

let makeTrace = (points, ~fromPin) => {
  let points = simplify(points)
  let lengths = [0.0]
  points->Array.forEachWithIndex((p, i) =>
    if i > 0 {
      let a = points->Array.getUnsafe(i - 1)
      let prev = lengths->Array.getUnsafe(i - 1)
      lengths->Array.push(prev +. Math.hypot(p.x -. a.x, p.y -. a.y))
    }
  )
  {points, lengths, total: lengths->Array.getUnsafe(Array.length(lengths) - 1), fromPin}
}

let pointAt = (trace, d) => {
  let d = Math.max(0.0, Math.min(trace.total, d))
  let i = ref(0)
  while (
    i.contents < Array.length(trace.lengths) - 2 &&
      trace.lengths->Array.getUnsafe(i.contents + 1) < d
  ) {
    i := i.contents + 1
  }
  let a = trace.points->Array.getUnsafe(i.contents)
  let b = trace.points->Array.getUnsafe(i.contents + 1)
  let l0 = trace.lengths->Array.getUnsafe(i.contents)
  let span = trace.lengths->Array.getUnsafe(i.contents + 1) -. l0
  let f = span > 0.0 ? (d -. l0) /. span : 0.0
  {x: a.x +. (b.x -. a.x) *. f, y: a.y +. (b.y -. a.y) *. f}
}

// Walks outward from `start`, sometimes bending 45 degrees, until it hits
// another trace, the window, or the screen edge.
let route = (~cols, ~rows, ~occupied, ~start, ~out, ~maxLen, ~random) => {
  let idx = ((c, r)) => r * cols + c
  let inside = ((c, r)) => c >= 0 && r >= 0 && c < cols && r < rows
  let free = cell => inside(cell) && !(occupied->Array.getUnsafe(idx(cell)))
  if !free(start) {
    None
  } else {
    let cells = [start]
    occupied->Array.setUnsafe(idx(start), true)
    let (ox, oy) = out
    let dir = ref(out)
    let pos = ref(start)
    let stop = ref(false)
    while !stop.contents && Array.length(cells) < maxLen {
      if Array.length(cells) > 2 && random() < 0.16 {
        let (dx, dy) = dir.contents
        dir := if dx == ox && dy == oy {
            let s = random() < 0.5 ? 1 : -1
            ox == 0 ? (s, oy) : (ox, s)
          } else {
            out
          }
      }
      let (dx, dy) = dir.contents
      let (c, r) = pos.contents
      let next = (c + dx, r + dy)
      let crossing = dx != 0 && dy != 0 && !free((c + dx, r)) && !free((c, r + dy))
      if free(next) && !crossing {
        occupied->Array.setUnsafe(idx(next), true)
        cells->Array.push(next)
        pos := next
      } else {
        stop := true
      }
    }
    Array.length(cells) >= 4 ? Some(cells) : None
  }
}

let center = ((c, r)) => {x: (Int.toFloat(c) +. 0.5) *. grid, y: (Int.toFloat(r) +. 0.5) *. grid}

let generate = (~width, ~height, ~window: Dom2.rect, ~random) => {
  let cols = Float.toInt(Math.ceil(width /. grid))
  let rows = Float.toInt(Math.ceil(height /. grid))
  let occupied = Array.make(~length=cols * rows, false)
  let cell = v => Float.toInt(Math.floor(v /. grid))
  let (c0, c1, r0, r1) = (
    cell(window.left),
    cell(window.right),
    cell(window.top),
    cell(window.bottom),
  )
  for r in Math.Int.max(0, r0) to Math.Int.min(rows - 1, r1) {
    for c in Math.Int.max(0, c0) to Math.Int.min(cols - 1, c1) {
      occupied->Array.setUnsafe(r * cols + c, true)
    }
  }
  let traces = []
  let maxLen = () => 6 + Float.toInt(random() *. 70.0)
  let pin = (~start, ~out, ~edge) =>
    if random() < 0.82 {
      switch route(~cols, ~rows, ~occupied, ~start, ~out, ~maxLen=maxLen(), ~random) {
      | Some(cells) =>
        traces->Array.push(makeTrace([edge]->Array.concat(cells->Array.map(center)), ~fromPin=true))
      | None => ()
      }
    }
  let rec along = (i, last, f) =>
    if i <= last {
      f(i)
      along(i + 2, last, f)
    }
  along(c0 + 1, c1 - 1, c => {
    let x = center((c, 0)).x
    pin(~start=(c, r0 - 1), ~out=(0, -1), ~edge={x, y: window.top})
    pin(~start=(c, r1 + 1), ~out=(0, 1), ~edge={x, y: window.bottom})
  })
  along(r0 + 1, r1 - 1, r => {
    let y = center((0, r)).y
    pin(~start=(c0 - 1, r), ~out=(-1, 0), ~edge={x: window.left, y})
    pin(~start=(c1 + 1, r), ~out=(1, 0), ~edge={x: window.right, y})
  })
  let dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
  for _ in 1 to cols * rows / 40 {
    let start = (
      Float.toInt(random() *. Int.toFloat(cols)),
      Float.toInt(random() *. Int.toFloat(rows)),
    )
    let out = dirs->Array.getUnsafe(Float.toInt(random() *. 4.0))
    switch route(
      ~cols,
      ~rows,
      ~occupied,
      ~start,
      ~out,
      ~maxLen=4 + Float.toInt(random() *. 24.0),
      ~random,
    ) {
    | Some(cells) => traces->Array.push(makeTrace(cells->Array.map(center), ~fromPin=false))
    | None => ()
    }
  }
  traces
}

let strokeTrace = (ctx, trace) => {
  ctx->beginPath
  trace.points->Array.forEachWithIndex((p, i) =>
    i == 0 ? ctx->moveTo(p.x, p.y) : ctx->lineTo(p.x, p.y)
  )
  ctx->stroke
  let last = trace.points->Array.getUnsafe(Array.length(trace.points) - 1)
  ctx->circle(last.x, last.y, 2.8)
  ctx->stroke
  let first = trace.points->Array.getUnsafe(0)
  if trace.fromPin {
    ctx->fillRect(first.x -. 2.0, first.y -. 2.0, 4.0, 4.0)
  } else {
    ctx->circle(first.x, first.y, 2.0)
    ctx->fill
  }
}

let make = (~width, ~height, ~window, ~random) => {
  let dpr = Math.min(2.0, Dom2.devicePixelRatio)
  let (pw, ph) = (Float.toInt(width *. dpr), Float.toInt(height *. dpr))
  let traces = generate(~width, ~height, ~window, ~random)
  let mask = offscreen(~width=pw, ~height=ph)
  let m = mask->getContext
  m->setTransform(dpr, 0.0, 0.0, dpr, 0.0, 0.0)
  m->strokeStyle("#fff")
  m->fillStyle("#fff")
  m->lineWidth(1.4)
  m->lineJoin("round")
  traces->Array.forEach(trace => m->strokeTrace(trace))
  let glow = offscreen(~width=pw, ~height=ph)
  let g = glow->getContext
  g->filter("blur(5px)")
  g->drawImage(mask, 0.0, 0.0)
  g->drawImage(mask, 0.0, 0.0)
  {
    width,
    height,
    dpr,
    traces,
    mask,
    glow,
    buffer: offscreen(~width=pw, ~height=ph),
    pulses: [],
    flashes: [],
    untilAmbient: 0.0,
  }
}

let addPulse = (board, pulse) =>
  if Array.length(board.pulses) < maxPulses {
    board.pulses->Array.push(pulse)
  }

let pick = arr => arr->Array.getUnsafe(Float.toInt(Math.random() *. Int.toFloat(Array.length(arr))))

// Fires request pulses down the traces whose pins are nearest (x, y).
let exchange = (board, ~x, ~y, ~count) => {
  let nearest =
    board.traces
    ->Array.mapWithIndex((trace, i) => (i, trace))
    ->Array.filter(((_, trace)) => trace.fromPin)
    ->Array.map(((i, trace)) => {
      let p = trace.points->Array.getUnsafe(0)
      (i, Math.hypot(p.x -. x, p.y -. y))
    })
    ->Array.toSorted(((_, a), (_, b)) => a -. b)
    ->Array.slice(~start=0, ~end=count)
  nearest->Array.forEach(((i, _)) =>
    board->addPulse({
      trace: i,
      dist: 0.0,
      speed: 320.0 +. Math.random() *. 200.0,
      dir: Out,
      color: pick(Palette.pulseColors),
      alpha: 1.0,
    })
  )
}

// The gateway lights up every pin at once.
let exchangeAll = board =>
  board.traces->Array.forEachWithIndex((trace, i) =>
    if trace.fromPin {
      board->addPulse({
        trace: i,
        dist: -.Math.random() *. 120.0,
        speed: 360.0 +. Math.random() *. 240.0,
        dir: Out,
        color: pick(Palette.pulseColors),
        alpha: 1.0,
      })
    }
  )

let ambient = (board, dt) => {
  board.untilAmbient = board.untilAmbient -. dt
  if board.untilAmbient <= 0.0 && Array.length(board.traces) > 0 {
    board.untilAmbient = 0.15 +. Math.random() *. 0.35
    board->addPulse({
      trace: Float.toInt(Math.random() *. Int.toFloat(Array.length(board.traces))),
      dist: 0.0,
      speed: 70.0 +. Math.random() *. 90.0,
      dir: Math.random() < 0.5 ? Out : Back,
      color: pick(Palette.pulseColors),
      alpha: 0.45,
    })
  }
}

let position = (board, pulse) => {
  let trace = board.traces->Array.getUnsafe(pulse.trace)
  pulse.dir == Out ? pointAt(trace, pulse.dist) : pointAt(trace, trace.total -. pulse.dist)
}

let update = (board, dt) => {
  board->ambient(dt)
  let arrived = []
  board.pulses =
    board.pulses->Array.filter(pulse => {
      pulse.dist = pulse.dist +. pulse.speed *. dt
      let trace = board.traces->Array.getUnsafe(pulse.trace)
      if pulse.dist >= trace.total {
        arrived->Array.push(pulse)
        false
      } else {
        true
      }
    })
  arrived->Array.forEach(pulse => {
    let trace = board.traces->Array.getUnsafe(pulse.trace)
    let p = pulse.dir == Out ? pointAt(trace, trace.total) : pointAt(trace, 0.0)
    if pulse.alpha > 0.5 {
      board.flashes->Array.push({
        fx: p.x,
        fy: p.y,
        age: 0.0,
        color: pulse.dir == Out ? pulse.color : Palette.success,
      })

      // The issuer answers: the token rides back to the window.
      if pulse.dir == Out && trace.fromPin {
        board->addPulse({
          ...pulse,
          dist: 0.0,
          dir: Back,
          color: Palette.success,
          speed: pulse.speed *. 1.2,
        })
      }
    }
  })
  board.flashes =
    board.flashes->Array.filter(f => {
      f.age = f.age +. dt
      f.age < 0.6
    })
}

let draw = (board, ctx, ~time) => {
  let (pw, ph) = (board.width *. board.dpr, board.height *. board.dpr)
  ctx->setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
  ctx->composite("source-over")
  let bg =
    ctx->radialGradient(pw /. 2.0, ph /. 2.0, 0.0, pw /. 2.0, ph /. 2.0, Math.max(pw, ph) *. 0.7)
  bg->addColorStop(0.0, "#161a22")
  bg->addColorStop(1.0, "#06070a")
  ctx->fillGradient(bg)
  ctx->fillRect(0.0, 0.0, pw, ph)

  // Holographic shimmer: the iridescent palette, slowly turning, seen
  // through the traces.
  let b = board.buffer->getContext
  b->setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
  b->composite("source-over")
  b->clearRect(0.0, 0.0, pw, ph)
  b->drawImage(board.glow, 0.0, 0.0)
  b->drawImage(board.mask, 0.0, 0.0)
  b->composite("source-in")
  let sheen =
    b->conicGradient(time *. 0.08, pw *. (0.5 +. 0.25 *. Math.sin(time *. 0.13)), ph *. 0.5)
  Palette.iridescent->Array.forEach(((stop, color)) => sheen->addColorStop(stop, color))
  b->fillGradient(sheen)
  b->fillRect(0.0, 0.0, pw, ph)
  b->composite("source-over")
  ctx->globalAlpha(0.55)
  ctx->drawImage(board.buffer, 0.0, 0.0)
  ctx->globalAlpha(1.0)

  ctx->setTransform(board.dpr, 0.0, 0.0, board.dpr, 0.0, 0.0)
  ctx->composite("lighter")
  board.pulses->Array.forEach(pulse =>
    if pulse.dist > 0.0 {
      ctx->fillStyle(pulse.color)
      for k in 0 to 9 {
        let behind = {...pulse, dist: pulse.dist -. Int.toFloat(k) *. 5.0}
        if behind.dist > 0.0 {
          let p = board->position(behind)
          ctx->globalAlpha(pulse.alpha *. (1.0 -. Int.toFloat(k) /. 10.0))
          ctx->circle(p.x, p.y, 3.0 -. Int.toFloat(k) *. 0.22)
          ctx->fill
        }
      }
      let p = board->position(pulse)
      ctx->globalAlpha(pulse.alpha *. 0.3)
      ctx->circle(p.x, p.y, 10.0)
      ctx->fill
    }
  )
  board.flashes->Array.forEach(f => {
    let k = f.age /. 0.6
    ctx->globalAlpha(1.0 -. k)
    ctx->strokeStyle(f.color)
    ctx->lineWidth(1.5)
    ctx->circle(f.fx, f.fy, 3.0 +. k *. 18.0)
    ctx->stroke
  })
  ctx->globalAlpha(1.0)
  ctx->composite("source-over")
}
