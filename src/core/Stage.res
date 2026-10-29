// Draws the game state and its short-lived effects onto the playfield canvas,
// delegating the themed parts to the theme's look.
open Canvas2d

let width = 880.0
let height = 540.0
let chipHeight = 32.0

type particle = {
  mutable x: float,
  mutable y: float,
  vx: float,
  mutable vy: float,
  mutable life: float,
  color: string,
}

type label = {text: string, lx: float, mutable ly: float, mutable age: float, tint: string}

type fx = {
  mutable particles: array<particle>,
  mutable labels: array<label>,
  mutable missed: array<(int, float)>,
  mutable breachFlash: float,
  mutable ring: option<(float, float, float)>,
}

let makeFx = () => {particles: [], labels: [], missed: [], breachFlash: 0.0, ring: None}

let pick = arr => arr->Array.getUnsafe(Float.toInt(Math.random() *. Int.toFloat(Array.length(arr))))

let burst = (fx, ~x, ~y, ~count, ~colors) =>
  for _ in 1 to count {
    let angle = Math.random() *. tau
    let speed = 60.0 +. Math.random() *. 220.0
    fx.particles->Array.push({
      x,
      y,
      vx: Math.cos(angle) *. speed,
      vy: Math.sin(angle) *. speed,
      life: 0.5 +. Math.random() *. 0.5,
      color: pick(colors),
    })
  }

let say = (fx, ~text, ~x, ~y, ~tint) => fx.labels->Array.push({text, lx: x, ly: y, age: 0.0, tint})

let center = (word: Engine.word) => (word.x +. word.width /. 2.0, word.y -. chipHeight /. 2.0)

let onEvent = (fx, theme: Theme.t, event: Engine.event) => {
  let look = theme.look
  switch event {
  | Captured(word) =>
    let (x, y) = center(word)
    fx->burst(~x, ~y, ~count=28, ~colors=look.sparks)
    fx->say(~text=theme.copy.captured, ~x, ~y, ~tint=look.captureTint)
  | BonusCaptured(spec, words) =>
    words->Array.forEach(word => {
      let (x, y) = center(word)
      fx->burst(~x, ~y, ~count=16, ~colors=look.sparks)
    })
    fx.ring = Some((width /. 2.0, height /. 2.0, 0.0))
    let cheer = theme->Theme.art(spec)->Option.mapOr(spec.label, art => art.cheer)
    fx->say(~text=cheer, ~x=width /. 2.0, ~y=height /. 2.0, ~tint=look.bonusTint)
  | Missed(_, Some(word)) =>
    let (x, y) = center(word)
    fx.missed->Array.push((word.id, 0.45))
    fx->say(~text=theme.copy.missed, ~x, ~y=y -. 18.0, ~tint=look.missTint)
  | Missed(_, None) => ()
  | Breached(word, cells) =>
    if cells > 0 {
      fx.breachFlash = 1.0
    }
    let (x, _) = center(word)
    fx->say(
      ~text=cells > 0 ? theme.copy.breached : theme.copy.wasted,
      ~x,
      ~y=height -. 36.0,
      ~tint=look.missTint,
    )
  | Spawned(_) => ()
  }
}

let update = (fx, dt) => {
  fx.particles =
    fx.particles->Array.filter(p => {
      p.x = p.x +. p.vx *. dt
      p.y = p.y +. p.vy *. dt
      p.vy = p.vy +. 160.0 *. dt
      p.life = p.life -. dt
      p.life > 0.0
    })
  fx.labels =
    fx.labels->Array.filter(l => {
      l.age = l.age +. dt
      l.ly = l.ly -. 30.0 *. dt
      l.age < 1.0
    })
  fx.missed = fx.missed->Array.filterMap(((id, t)) => t -. dt > 0.0 ? Some((id, t -. dt)) : None)
  fx.breachFlash = Math.max(0.0, fx.breachFlash -. dt *. 2.5)
  fx.ring = switch fx.ring {
  | Some((x, y, age)) if age < 1.0 => Some((x, y, age +. dt))
  | _ => None
  }
}

let drawBonus = (ctx, theme: Theme.t, bonus: Engine.bonus, ~input, ~time) =>
  switch theme->Theme.art(bonus.spec) {
  | Some(art) =>
    let x = bonus.x
    let y = Engine.bonusY(bonus)
    ctx->save
    ctx->translate(x, y)
    art.draw(ctx, bonus, ~time)
    ctx->restore
    let look = theme.look
    ctx->save
    ctx->textBaseline("middle")
    let wordWidth = ctx->Text.width(~font=look.bonusFont, bonus.spec.word)
    ctx
    ->Text.split(
      ~text=bonus.spec.word,
      ~input,
      ~x=x +. (art.width -. wordWidth) /. 2.0,
      ~y=y +. art.height +. 16.0,
      ~color=look.ink,
      ~matchColor=look.match,
    )
    ->ignore
    let captionFont = `600 9px ${look.labelFont}`
    let captionWidth = ctx->Text.width(~font=captionFont, art.caption)
    ctx->fillStyle(look.inkMuted)
    ctx->fillText(art.caption, x +. (art.width -. captionWidth) /. 2.0, y +. art.height +. 32.0)
    ctx->restore
  | None => ()
  }

let drawFx = (ctx, theme: Theme.t, fx) => {
  let look = theme.look
  ctx->composite("lighter")
  fx.particles->Array.forEach(p => {
    ctx->globalAlpha(Math.min(1.0, p.life *. 2.0))
    ctx->fillStyle(p.color)
    ctx->circle(p.x, p.y, 2.0)
    ctx->fill
  })
  switch fx.ring {
  | Some((x, y, age)) =>
    ctx->globalAlpha(1.0 -. age)
    ctx->strokeStyle(look.bonusTint)
    ctx->lineWidth(3.0)
    ctx->circle(x, y, age *. width *. 0.7)
    ctx->stroke
  | None => ()
  }
  ctx->composite("source-over")
  ctx->font(`600 12px ${look.labelFont}`)
  ctx->textAlign("center")
  fx.labels->Array.forEach(l => {
    ctx->globalAlpha(1.0 -. l.age)
    ctx->fillStyle(l.tint)
    ctx->fillText(l.text, l.lx, l.ly)
  })
  ctx->textAlign("start")
  ctx->globalAlpha(1.0)
  if fx.breachFlash > 0.0 {
    let glow = ctx->linearGradient(0.0, height, 0.0, height -. 120.0)
    glow->addColorStop(0.0, `rgba(255, 99, 105, ${Float.toString(0.45 *. fx.breachFlash)})`)
    glow->addColorStop(1.0, "rgba(255, 99, 105, 0)")
    ctx->fillGradient(glow)
    ctx->fillRect(0.0, height -. 120.0, width, 120.0)
  }
}

let draw = (ctx, ~dpr, ~theme: Theme.t, ~state: Engine.state, ~fx, ~time) => {
  let look = theme.look
  ctx->setTransform(dpr, 0.0, 0.0, dpr, 0.0, 0.0)
  look.background(ctx, ~width, ~height, ~time)
  state.words->Array.forEach(word =>
    look.word(
      ctx,
      word,
      ~input=state.input,
      ~missed=fx.missed->Array.some(((id, _)) => id == word.id),
      ~time,
    )
  )
  switch state.bonus {
  | Some(bonus) => ctx->drawBonus(theme, bonus, ~input=state.input, ~time)
  | None => ()
  }
  look.base(ctx, state.shield, ~y=height -. Engine.shieldHeight)
  ctx->drawFx(theme, fx)
}
