@module("vitest") external describe: (string, unit => unit) => unit = "describe"
@module("vitest") external test: (string, unit => unit) => unit = "test"
type expectation
@module("vitest") external expect: 'a => expectation = "expect"
@send external toBe: (expectation, 'a) => unit = "toBe"
@send external toEqual: (expectation, 'a) => unit = "toEqual"

let bonusSpec = (~word, ~kind): Engine.bonusSpec => {
  word,
  label: word,
  kind,
  chancePerSecond: 0.0,
  minElapsed: 0.0,
  speed: 100.0,
}

let config: Engine.config = {
  width: 100.0,
  height: 100.0,
  shieldCells: 10,
  baseInset: 0.0,
  measure: text => Int.toFloat(String.length(text)) *. 10.0,
  random: () => 0.0,
  rules: {vocabulary: ["abc"], bonuses: []},
}

let slow: Tier.t = {...Tier.standard, id: "slow", speed: 0.75, requestRate: 0.8, scoreMultiplier: 1}
let fast: Tier.t = {...Tier.standard, id: "fast", speed: 1.4, requestRate: 1.35, scoreMultiplier: 3}

let word = (~id, ~text, ~x=0.0, ~y=10.0): Engine.word => {
  id,
  text,
  x,
  y,
  velocity: 40.0,
  width: config.measure(text),
}

let withWords = words => {...Engine.init(config), words}

let withBonus = (state: Engine.state, spec) => {...state, bonus: Some({spec, x: 10.0, age: 0.0})}

let typeAll = (state, text) =>
  text
  ->String.split("")
  ->Array.reduce((state, []), ((state, events), key) => {
    let (next, more) = state->Engine.typeKey(key)
    (next, events->Array.concat(more))
  })

let rowFor = (state: Engine.state, term) => state.audit.rows->Array.find(row => row.term == term)

describe("Shield", () => {
  test("breaches only the cells beneath a span, counting newly breached cells", () => {
    let shield = Shield.make(~cells=10, ~width=100.0)
    let (shield, first) = shield->Shield.breach(~left=12.0, ~right=38.0)
    expect(first)->toBe(3)
    let (shield, again) = shield->Shield.breach(~left=20.0, ~right=45.0)
    expect(again)->toBe(1)
    expect(Shield.intactCount(shield))->toBe(6)
  })

  test("an inset base breaches by its own position, and not outside it", () => {
    let shield = Shield.make(~cells=10, ~left=20.0, ~width=100.0)
    let (shield, edge) = shield->Shield.breach(~left=0.0, ~right=25.0)
    expect(edge)->toBe(1)
    expect(shield.cells->Array.getUnsafe(0))->toBe(false)
    let (shield, margin) = shield->Shield.breach(~left=125.0, ~right=140.0)
    expect(margin)->toBe(0)
    let (_, before) = shield->Shield.breach(~left=0.0, ~right=20.0)
    expect(before)->toBe(0)
  })

  test("is down once every cell is breached", () => {
    let (shield, _) = Shield.make(~cells=4, ~width=40.0)->Shield.breach(~left=0.0, ~right=40.0)
    expect(Shield.isDown(shield))->toBe(true)
    expect(Shield.integrity(shield))->toBe(0.0)
  })

  test("repairs breached cells nearest the middle first", () => {
    let (shield, _) = Shield.make(~cells=6, ~width=60.0)->Shield.breach(~left=0.0, ~right=60.0)
    expect(shield->Shield.repair(2)->(s => s.Shield.cells))->toEqual([
      false,
      false,
      true,
      true,
      false,
      false,
    ])
  })
})

describe("Audit", () => {
  test("keeps one row per term with granted and denied counts, newest first", () => {
    let log =
      Audit.empty
      ->Audit.record("GitHub", Granted)
      ->Audit.record("Slack", Denied)
      ->Audit.record("GitHub", Denied)
      ->Audit.record("GitHub", Granted)
    let rows = Audit.recent(log)
    expect(rows->Array.map(row => (row.term, row.granted, row.denied)))->toEqual([
      ("GitHub", 2, 1),
      ("Slack", 0, 1),
    ])
  })
})

describe("Engine.typeKey", () => {
  test("typing a word captures it, case-insensitively", () => {
    let (state, events) =
      withWords([word(~id=1, ~text="GitHub"), word(~id=2, ~text="Slack")])->typeAll("github")
    expect(state.words->Array.map(w => w.text))->toEqual(["Slack"])
    expect(state.input)->toBe("")
    expect(state.captures)->toBe(1)
    expect(Array.length(events))->toBe(1)
    expect(rowFor(state, "GitHub")->Option.map(row => (row.granted, row.denied)))->toEqual(
      Some((1, 0)),
    )
  })

  test("a typo after a prefix is a miss for the lowest matching word", () => {
    let state = withWords([
      word(~id=1, ~text="Slack", ~y=20.0),
      word(~id=2, ~text="Snowflake", ~y=60.0),
    ])
    let (state, _) = state->typeAll("sx")
    expect(state.input)->toBe("")
    expect(rowFor(state, "Snowflake")->Option.map(row => row.denied))->toEqual(Some(1))
    expect(rowFor(state, "Slack"))->toEqual(None)
  })

  test("a stray key that starts nothing is ignored", () => {
    let (state, events) = withWords([word(~id=1, ~text="Slack")])->Engine.typeKey("q")
    expect(state.input)->toBe("")
    expect(Array.length(events))->toBe(0)
    expect(state.audit.seq)->toBe(0)
  })

  test("a clear-all bonus captures every word with a single logged capture", () => {
    let state =
      withWords([
        word(~id=1, ~text="GitHub"),
        word(~id=2, ~text="Slack"),
        word(~id=3, ~text="Jira"),
      ])->withBonus(bonusSpec(~word="everything", ~kind=ClearAll))
    let (state, _) = state->typeAll("everything")
    expect(Array.length(state.words))->toBe(0)
    expect(state.bonus)->toEqual(None)
    expect(state.captures)->toBe(3)
    expect(state.audit.rows->Array.map(row => (row.term, row.granted)))->toEqual([
      ("everything", 1),
    ])
  })

  test("a slow-time bonus slows falling words for its duration", () => {
    let state =
      withWords([word(~id=1, ~text="abc", ~y=10.0)])->withBonus(
        bonusSpec(~word="bee", ~kind=SlowTime(5.0)),
      )
    let (state, _) = state->typeAll("bee")
    let (state, _) = state->Engine.step(config, 0.1)
    let first: Engine.word = state.words->Array.getUnsafe(0)
    expect(first.y)->toBe(10.0 +. 40.0 *. 0.1 *. Engine.slowFactor)
  })

  test("a double-points bonus doubles the next captures", () => {
    let words = [word(~id=1, ~text="Slack")]
    let (plain, _) = withWords(words)->typeAll("slack")
    let (boosted, _) =
      withWords(words)
      ->withBonus(bonusSpec(~word="cardinal", ~kind=DoublePoints(8.0)))
      ->typeAll("cardinalslack")
    expect(boosted.score)->toBe(plain.score * 2)
  })

  test("a repair bonus restores breached cells", () => {
    let (shield, _) = Shield.make(~cells=10, ~width=100.0)->Shield.breach(~left=0.0, ~right=50.0)
    let state = {...withWords([]), shield}->withBonus(bonusSpec(~word="rabbit", ~kind=Repair(3)))
    let (state, _) = state->typeAll("rabbit")
    expect(Shield.intactCount(state.shield))->toBe(8)
  })

  test("backspace edits the input", () => {
    let (state, _) = withWords([word(~id=1, ~text="Slack")])->typeAll("sla")
    expect(Engine.backspace(state).input)->toBe("sl")
  })
})

describe("Engine.step", () => {
  test("a word that reaches the floor breaches the cells beneath it", () => {
    let state = withWords([word(~id=1, ~text="abc", ~x=0.0, ~y=99.0)])
    let (state, events) = state->Engine.step(config, 0.1)
    expect(Shield.intactCount(state.shield))->toBe(7)
    expect(
      events->Array.some(
        event =>
          switch event {
          | Breached(_, 3) => true
          | _ => false
          },
      ),
    )->toBe(true)
  })

  test("the game is over when the base is gone", () => {
    let state = withWords([word(~id=1, ~text="abcdefghij", ~x=0.0, ~y=99.0)])
    let (state, _) = state->Engine.step(config, 0.1)
    expect(state.over)->toBe(true)
  })

  test("spawns words from the vocabulary over time", () => {
    let (state, _) = Engine.init(config)->Engine.step(config, 0.6)
    expect(state.words->Array.map(w => w.text))->toEqual(["abc"])
  })
})

describe("Tier", () => {
  test("a faster tier requests words sooner and drops them faster", () => {
    let slowState = Engine.init(~tier=slow, config)
    let fastState = Engine.init(~tier=fast, config)
    expect(Engine.spawnInterval(fastState) < Engine.spawnInterval(slowState))->toBe(true)
    let (slowState, _) = slowState->Engine.step(config, 0.6)
    let (fastState, _) = fastState->Engine.step(config, 0.6)
    let velocity = (state: Engine.state) => {
      let first: Engine.word = state.words->Array.getUnsafe(0)
      first.velocity
    }
    expect(velocity(fastState) > velocity(slowState))->toBe(true)
  })

  test("higher tiers score more per capture", () => {
    let words = [word(~id=1, ~text="Slack")]
    let (low, _) = {...Engine.init(~tier=slow, config), words}->typeAll("slack")
    let (high, _) = {...Engine.init(~tier=fast, config), words}->typeAll("slack")
    expect(high.score)->toBe(low.score * 3)
  })

  test("cycles through tiers in both directions", () => {
    let tiers = [slow, Tier.standard, fast]
    expect(tiers->Tier.next(fast, 1)->(t => t.Tier.id))->toBe("slow")
    expect(tiers->Tier.next(slow, -1)->(t => t.Tier.id))->toBe("fast")
  })
})
