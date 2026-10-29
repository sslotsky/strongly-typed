// The Gig's bandstand: a drummer and a bassist behind you, a neon sign, a
// staff that fills with the notes you play and a crowd that gets into it as
// your streak grows. Fluff two tunes in a row (or one after a long clean run)
// and the drummer throws a cymbal at you, the way Jo Jones did at Bird in 1937.
open Canvas2d

type flight = {mutable ft: float, tx: float, ty: float}
type note = {sx: float, sy: float, tx: float, ty: float, mutable nt: float}
type crash = {cx: float, cy: float, mutable ct: float}

let ink = "#f7ecd9"
let amber = "#ffb347"
let brass = "#d9a441"
let shadow = "#45323f"
let serif = "Fraunces, Georgia, serif"
let flightTime = 0.75
let crashTime = 1.1
let noteLife = 5.0
let staffTop = 30.0
let staffGap = 7.0

let whoosh = () =>
  Synth.play(ctx => ctx->Synth.noise(~duration=0.6, ~volume=0.05, ~from=1800.0, ~to_=7000.0))

let crashSound = () =>
  Synth.play(ctx => {
    ctx->Synth.noise(~duration=1.8, ~volume=0.24, ~from=16000.0, ~to_=3000.0)
    ctx->Synth.tone(
      ~kind="triangle",
      ~from=640.0,
      ~to_=600.0,
      ~at=0.0,
      ~duration=0.6,
      ~volume=0.025,
    )
  })

let cymbal = (ctx, ~x, ~y, ~rx, ~ry, ~tilt) => {
  ctx->fillStyle(brass)
  ctx->oval(x, y, rx, ry, tilt)
  ctx->fill
  ctx->strokeStyle("#8a6420")
  ctx->lineWidth(1.0)
  ctx->stroke
  ctx->fillStyle("#b8862c")
  ctx->oval(x, y, rx *. 0.18, Math.max(1.0, ry *. 0.4), tilt)
  ctx->fill
}

let drummer = (ctx, ~ground, ~time, ~armed) => {
  let beat = Math.sin(time *. 9.0)
  ctx->fillStyle(shadow)
  ctx->circle(62.0, ground -. 118.0, 11.0)
  ctx->fill
  ctx->oval(62.0, ground -. 82.0, 16.0, 26.0, 0.0)
  ctx->fill
  ctx->fillStyle("#3a2a30")
  ctx->circle(92.0, ground -. 32.0, 30.0)
  ctx->fill
  ctx->strokeStyle(brass)
  ctx->lineWidth(2.0)
  ctx->stroke
  ctx->fillStyle("#3a2a30")
  ctx->oval(122.0, ground -. 70.0, 17.0, 5.0, 0.0)
  ctx->fill
  ctx->strokeStyle(shadow)
  ctx->lineWidth(5.0)
  ctx->beginPath
  ctx->moveTo(70.0, ground -. 96.0)
  ctx->lineTo(104.0, ground -. 80.0 -. beat *. 5.0)
  ctx->stroke
  ctx->strokeStyle(ink)
  ctx->lineWidth(1.5)
  ctx->beginPath
  ctx->moveTo(104.0, ground -. 80.0 -. beat *. 5.0)
  ctx->lineTo(124.0, ground -. 90.0 -. beat *. 10.0)
  ctx->stroke
  ctx->strokeStyle("#5a4a40")
  ctx->beginPath
  ctx->moveTo(140.0, ground -. 4.0)
  ctx->lineTo(132.0, ground -. 128.0)
  ctx->stroke
  if armed {
    ctx->cymbal(~x=132.0, ~y=ground -. 130.0, ~rx=22.0, ~ry=4.5, ~tilt=-0.15)
  }
}

let bassist = (ctx, ~x, ~ground, ~time) => {
  ctx->fillStyle(shadow)
  ctx->circle(x, ground -. 128.0, 10.0)
  ctx->fill
  ctx->oval(x, ground -. 92.0, 14.0, 26.0, 0.0)
  ctx->fill
  ctx->fillStyle("#6b3a1e")
  ctx->oval(x -. 24.0, ground -. 46.0, 20.0, 26.0, 0.1)
  ctx->fill
  ctx->oval(x -. 27.0, ground -. 84.0, 14.0, 18.0, 0.1)
  ctx->fill
  ctx->strokeStyle("#3a2015")
  ctx->lineWidth(4.0)
  ctx->beginPath
  ctx->moveTo(x -. 28.0, ground -. 98.0)
  ctx->lineTo(x -. 36.0, ground -. 168.0)
  ctx->stroke
  ctx->strokeStyle(shadow)
  ctx->lineWidth(5.0)
  ctx->beginPath
  ctx->moveTo(x -. 6.0, ground -. 92.0)
  ctx->lineTo(x -. 22.0, ground -. 62.0 +. Math.sin(time *. 7.0) *. 3.0)
  ctx->stroke
}

let neon = (ctx, ~x, ~y, ~time) => {
  let flicker = cycle(time, 7.0)
  let dim = flicker > 3.1 && flicker < 3.3
  ctx->save
  ctx->globalAlpha(dim ? 0.2 : 0.75)
  ctx->font(`italic 700 18px ${serif}`)
  ctx->shadowColor("#ff5d9e")
  ctx->shadowBlur(14.0)
  ctx->fillStyle("#ff8fbf")
  ctx->fillText("OPEN LATE", x, y)
  ctx->restore
}

let make = (stage: Theme.stage): Theme.scene => {
  let width = stage.width
  let ground = stage.height -. Engine.shieldHeight
  let misses = ref(0)
  let clean = ref(0)
  let flight: ref<option<flight>> = ref(None)
  let crashes: ref<array<crash>> = ref([])
  let notes: ref<array<note>> = ref([])
  let played = ref(0)
  let clap = ref(0.0)
  let boo = ref(0.0)

  let addNote = (word: Engine.word) => {
    let slot = Int.toFloat(played.contents - played.contents / 18 * 18)
    played := played.contents + 1
    notes.contents->Array.push({
      sx: word.x +. word.width /. 2.0,
      sy: word.y -. 16.0,
      tx: 70.0 +. slot *. 42.0,
      ty: staffTop +. Math.floor(Math.random() *. 9.0) *. staffGap /. 2.0,
      nt: 0.0,
    })
  }

  let throw = (target: option<Engine.word>) => {
    let (tx, ty) = switch target {
    | Some(word) => (word.x +. word.width /. 2.0, word.y -. 16.0)
    | None => (width /. 2.0, ground -. 24.0)
    }
    flight := Some({ft: 0.0, tx, ty})
    whoosh()
  }

  {
    onEvent: event =>
      switch event {
      | Captured(word) =>
        clean := clean.contents + 1
        misses := 0
        addNote(word)
        if clean.contents - clean.contents / 5 * 5 == 0 {
          clap := 0.9
        }
      | BonusCaptured(_, words) =>
        words->Array.forEach(addNote)
        clap := 1.4
      | Missed(_, target) =>
        misses := misses.contents + 1
        if flight.contents == None && (misses.contents >= 2 || clean.contents >= 8) {
          throw(target)
          misses := 0
        }
        clean := 0
      | Breached(_, cells) =>
        if cells > 0 {
          boo := 1.4
        }
      | Spawned(_) => ()
      },
    update: dt => {
      notes.contents =
        notes.contents->Array.filter(n => {
          n.nt = n.nt +. dt
          n.nt < noteLife
        })
      clap := Math.max(0.0, clap.contents -. dt)
      boo := Math.max(0.0, boo.contents -. dt)
      switch flight.contents {
      | Some(f) =>
        f.ft = f.ft +. dt
        if f.ft >= flightTime {
          flight := None
          crashes.contents->Array.push({cx: f.tx, cy: f.ty, ct: 0.0})
          stage.shake(0.9)
          crashSound()
        }
      | None => ()
      }
      crashes.contents =
        crashes.contents->Array.filter(c => {
          c.ct = c.ct +. dt
          c.ct < crashTime
        })
    },
    drawBack: (ctx, ~time) => {
      ctx->globalAlpha(0.16)
      ctx->strokeStyle(ink)
      ctx->lineWidth(1.0)
      for k in 0 to 4 {
        let y = staffTop +. Int.toFloat(k) *. staffGap
        ctx->beginPath
        ctx->moveTo(40.0, y)
        ctx->lineTo(width -. 40.0, y)
        ctx->stroke
      }
      ctx->globalAlpha(0.7)
      ctx->neon(~x=width -. 210.0, ~y=110.0, ~time)
      ctx->globalAlpha(0.8)
      let armed = flight.contents == None && Array.length(crashes.contents) == 0
      ctx->drummer(~ground, ~time, ~armed)
      ctx->bassist(~x=width -. 60.0, ~ground, ~time)
      // The crowd bobs harder the longer your streak runs.
      let energy = Math.min(1.0, Int.toFloat(clean.contents) /. 10.0)
      ctx->globalAlpha(0.9)
      for i in 0 to 13 {
        let fi = Int.toFloat(i)
        let x = 190.0 +. fi *. 36.0
        let bob =
          Math.abs(Math.sin(time *. (3.0 +. energy *. 3.0) +. fi *. 1.3)) *. (1.0 +. energy *. 5.0)
        ctx->fillStyle("#1a1218")
        ctx->oval(x, ground +. 2.0, 15.0, 9.0, 0.0)
        ctx->fill
        ctx->circle(x, ground -. 10.0 -. bob, 8.5)
        ctx->fill
        if clap.contents > 0.0 && i - i / 2 * 2 == 0 {
          let up = Math.sin(time *. 22.0 +. fi) > 0.0 ? 2.0 : 0.0
          ctx->circle(x -. 9.0, ground -. 30.0 -. bob -. up, 3.0)
          ctx->fill
          ctx->circle(x +. 9.0, ground -. 30.0 -. bob -. up, 3.0)
          ctx->fill
        }
      }
      ctx->globalAlpha(1.0)
    },
    drawFront: (ctx, ~time as _) => {
      notes.contents->Array.forEach(n => {
        let p = Math.min(1.0, n.nt /. 0.6)
        let ease = 1.0 -. (1.0 -. p) *. (1.0 -. p)
        let x = lerp(n.sx, n.tx, ease)
        let y = lerp(n.sy, n.ty, ease)
        ctx->globalAlpha(
          n.nt < 1.0 ? 1.0 : Math.max(0.0, 1.0 -. (n.nt -. 1.0) /. (noteLife -. 1.0)),
        )
        ctx->fillStyle(amber)
        ctx->oval(x, y, 4.6, 3.3, -0.35)
        ctx->fill
        ctx->strokeStyle(amber)
        ctx->lineWidth(1.3)
        ctx->beginPath
        ctx->moveTo(x +. 4.2, y)
        ctx->lineTo(x +. 4.2, y -. 17.0)
        ctx->stroke
      })
      ctx->globalAlpha(1.0)
      switch flight.contents {
      | Some(f) =>
        let p = f.ft /. flightTime
        let x = lerp(132.0, f.tx, p)
        let y = lerp(ground -. 130.0, f.ty, p) -. Math.sin(Math.Constants.pi *. p) *. 120.0
        let spin = f.ft *. 22.0
        ctx->cymbal(
          ~x,
          ~y,
          ~rx=22.0,
          ~ry=Math.max(2.0, 20.0 *. Math.abs(Math.cos(spin))),
          ~tilt=spin *. 0.3,
        )
      | None => ()
      }
      crashes.contents->Array.forEach(c => {
        let p = c.ct /. crashTime
        ctx->globalAlpha(1.0 -. p)
        ctx->strokeStyle(amber)
        ctx->lineWidth(2.0)
        for k in 0 to 11 {
          let a = Int.toFloat(k) /. 12.0 *. tau
          let r0 = 16.0 +. p *. 40.0
          let r1 = 30.0 +. p *. 90.0
          ctx->beginPath
          ctx->moveTo(c.cx +. Math.cos(a) *. r0, c.cy +. Math.sin(a) *. r0)
          ctx->lineTo(c.cx +. Math.cos(a) *. r1, c.cy +. Math.sin(a) *. r1)
          ctx->stroke
        }
        // The cymbal clatters to the floor.
        let fall = Math.min(ground -. 6.0, c.cy +. p *. p *. 260.0)
        ctx->cymbal(
          ~x=c.cx +. p *. 50.0,
          ~y=fall,
          ~rx=22.0,
          ~ry=Math.max(2.0, 18.0 *. Math.abs(Math.cos(c.ct *. 14.0))),
          ~tilt=c.ct *. 3.0,
        )
        ctx->font(`italic 800 34px ${serif}`)
        ctx->textAlign("center")
        ctx->fillStyle(brass)
        ctx->fillText("CRASH!", c.cx, c.cy -. 34.0 -. p *. 24.0)
        ctx->textAlign("start")
      })
      ctx->globalAlpha(1.0)
      if boo.contents > 0.0 {
        let x = width -. 250.0
        let y = ground -. 58.0
        ctx->globalAlpha(Math.min(1.0, boo.contents /. 0.3))
        ctx->fillStyle(ink)
        ctx->roundRect(x, y, 54.0, 26.0, 8.0)
        ctx->fill
        ctx->beginPath
        ctx->moveTo(x +. 14.0, y +. 26.0)
        ctx->lineTo(x +. 10.0, y +. 36.0)
        ctx->lineTo(x +. 24.0, y +. 26.0)
        ctx->fill
        ctx->font(`italic 700 15px ${serif}`)
        ctx->fillStyle("#1a1218")
        ctx->fillText("Boo!", x +. 10.0, y +. 18.0)
        ctx->globalAlpha(1.0)
      }
    },
  }
}
