// The theme-agnostic game: words fall, typing captures them, bonuses drift by.
type word = {id: int, text: string, x: float, y: float, velocity: float, width: float}

type bonusKind =
  | ClearAll
  | SlowTime(float)
  | DoublePoints(float)
  | Repair(int)

type bonusSpec = {
  word: string,
  // The row this bonus gets in the log.
  label: string,
  kind: bonusKind,
  chancePerSecond: float,
  minElapsed: float,
  speed: float,
}

type bonus = {spec: bonusSpec, x: float, age: float}

type event =
  | Captured(word)
  | BonusCaptured(bonusSpec, array<word>)
  | Missed(string, option<word>)
  | Breached(word, int)
  | Spawned(word)

type rules = {vocabulary: array<string>, bonuses: array<bonusSpec>}

type config = {
  width: float,
  height: float,
  shieldCells: int,
  measure: string => float,
  random: unit => float,
  rules: rules,
}

type state = {
  words: array<word>,
  input: string,
  shield: Shield.t,
  bonus: option<bonus>,
  audit: Audit.t,
  score: int,
  captures: int,
  elapsed: float,
  untilSpawn: float,
  nextId: int,
  tier: Tier.t,
  slowUntil: float,
  doubleUntil: float,
  over: bool,
}

let shieldHeight = 14.0
let spawnY = 34.0
let slowFactor = 0.4

let init = (~tier=Tier.standard, config) => {
  words: [],
  input: "",
  shield: Shield.make(~cells=config.shieldCells, ~width=config.width),
  bonus: None,
  audit: Audit.empty,
  score: 0,
  captures: 0,
  elapsed: 0.0,
  untilSpawn: 0.5,
  nextId: 1,
  tier,
  slowUntil: 0.0,
  doubleUntil: 0.0,
  over: false,
}

let normalize = String.toLowerCase

let isPrefix = (input, text) => input != "" && normalize(text)->String.startsWith(normalize(input))

let matches = (input, text) => normalize(input) == normalize(text)

let slowed = state => state.elapsed < state.slowUntil

let doubled = state => state.elapsed < state.doubleUntil

// Difficulty ramps with captures (spawn faster, fall faster), on top of the
// tier's base pace.
let spawnInterval = state =>
  Math.max(0.55, 1.9 -. Int.toFloat(state.captures) *. 0.03) /. state.tier.requestRate

let speedBoost = state => Math.min(1.6, Int.toFloat(state.captures) *. 0.02)

// How far the ramp has pushed the fall speed past the tier's starting pace.
let pace = state => 1.0 +. speedBoost(state) *. 40.0 /. 44.0

let spawn = (state, config) => {
  let vocabulary = config.rules.vocabulary
  let text =
    vocabulary->Array.getUnsafe(
      Float.toInt(config.random() *. Int.toFloat(Array.length(vocabulary))),
    )
  let width = config.measure(text)
  let word = {
    id: state.nextId,
    text,
    width,
    x: config.random() *. Math.max(0.0, config.width -. width),
    y: spawnY,
    velocity: (28.0 +. config.random() *. 32.0 +. speedBoost(state) *. 40.0) *. state.tier.speed,
  }
  ({...state, words: state.words->Array.concat([word]), nextId: state.nextId + 1}, word)
}

let pointsFor = (state, word) =>
  String.length(word.text) *
  Float.toInt(word.velocity /. 4.0) *
  state.tier.scoreMultiplier * (doubled(state) ? 2 : 1)

let capture = (state, captured) => {
  let audit =
    captured->Array.reduce(state.audit, (log, word) => log->Audit.record(word.text, Granted))
  let score = captured->Array.reduce(state.score, (sum, word) => sum + pointsFor(state, word))
  {
    ...state,
    words: state.words->Array.filter(word => !(captured->Array.some(c => c.id == word.id))),
    audit,
    score,
    captures: state.captures + Array.length(captured),
    input: "",
  }
}

// The word the player was most plausibly typing: the lowest one on screen.
let target = (state, input) =>
  state.words
  ->Array.filter(word => isPrefix(input, word.text))
  ->Array.reduce(None, (best: option<word>, word: word) =>
    switch best {
    | Some(b) if b.y >= word.y => best
    | _ => Some(word)
    }
  )

let captureBonus = (state, spec) => {
  let state = {
    ...state,
    bonus: None,
    input: "",
    audit: state.audit->Audit.record(spec.label, Granted),
  }
  switch spec.kind {
  | ClearAll =>
    let cleared = state.words
    let score = cleared->Array.reduce(state.score, (sum, word) => sum + pointsFor(state, word))
    (
      {...state, words: [], score, captures: state.captures + Array.length(cleared)},
      [BonusCaptured(spec, cleared)],
    )
  | SlowTime(seconds) => (
      {...state, slowUntil: state.elapsed +. seconds},
      [BonusCaptured(spec, [])],
    )
  | DoublePoints(seconds) => (
      {...state, doubleUntil: state.elapsed +. seconds},
      [BonusCaptured(spec, [])],
    )
  | Repair(cells) => (
      {...state, shield: state.shield->Shield.repair(cells)},
      [BonusCaptured(spec, [])],
    )
  }
}

let bonusPrefix = (state, input) =>
  switch state.bonus {
  | Some(b) => isPrefix(input, b.spec.word)
  | None => false
  }

let typeKey = (state, key) =>
  if state.over {
    (state, [])
  } else {
    let input = state.input ++ key
    let captured = state.words->Array.filter(word => matches(input, word.text))
    switch state.bonus {
    | Some(b) if matches(input, b.spec.word) => captureBonus(state, b.spec)
    | _ =>
      if Array.length(captured) > 0 {
        (capture(state, captured), captured->Array.map(word => Captured(word)))
      } else if (
        bonusPrefix(state, input) || state.words->Array.some(word => isPrefix(input, word.text))
      ) {
        ({...state, input}, [])
      } else if state.input == "" {
        // A stray key that starts nothing isn't an attempt.
        (state, [])
      } else {
        switch (target(state, state.input), state.bonus) {
        | (Some(word), _) => (
            {...state, input: "", audit: state.audit->Audit.record(word.text, Denied)},
            [Missed(word.text, Some(word))],
          )
        | (None, Some(b)) if isPrefix(state.input, b.spec.word) => (
            {...state, input: "", audit: state.audit->Audit.record(b.spec.label, Denied)},
            [Missed(b.spec.label, None)],
          )
        | (None, _) => ({...state, input: ""}, [])
        }
      }
    }
  }

let backspace = state => {...state, input: state.input->String.slice(~start=0, ~end=-1)}

let bonusY = bonus => 70.0 +. 34.0 *. Math.sin(bonus.age *. 3.2)

let stepBonus = (state, config, dt, motion) =>
  switch state.bonus {
  | Some(b) =>
    let x = b.x +. b.spec.speed *. motion
    x > config.width ? None : Some({...b, x, age: b.age +. dt})
  | None =>
    config.rules.bonuses
    ->Array.find(spec =>
      state.elapsed > spec.minElapsed && config.random() < spec.chancePerSecond *. dt
    )
    ->Option.map(spec => {spec, x: -110.0, age: 0.0})
  }

let step = (state, config, dt) =>
  if state.over {
    (state, [])
  } else {
    let events = []
    // Slow time stretches motion, not the clock.
    let motion = slowed(state) ? dt *. slowFactor : dt
    let floor = config.height -. shieldHeight
    let moved = state.words->Array.map(word => {...word, y: word.y +. word.velocity *. motion})
    let landed = moved->Array.filter(word => word.y >= floor)
    let falling = moved->Array.filter(word => word.y < floor)
    let shield = landed->Array.reduce(state.shield, (shield, word) => {
      let (next, breached) = shield->Shield.breach(~left=word.x, ~right=word.x +. word.width)
      events->Array.push(Breached(word, breached))
      next
    })
    let next = {
      ...state,
      words: falling,
      shield,
      elapsed: state.elapsed +. dt,
      untilSpawn: state.untilSpawn -. motion,
      bonus: stepBonus(state, config, dt, motion),
    }
    let next = if next.untilSpawn <= 0.0 {
      let (spawned, word) = spawn(next, config)
      events->Array.push(Spawned(word))
      {...spawned, untilSpawn: spawnInterval(spawned)}
    } else {
      next
    }
    let input =
      next.input != "" &&
      !(next.words->Array.some(word => isPrefix(next.input, word.text))) &&
      !bonusPrefix(next, next.input)
        ? ""
        : next.input
    ({...next, input, over: Shield.isDown(shield)}, events)
  }
