type phase = Title | Playing | Paused | Over

type hud = {
  phase: phase,
  input: string,
  score: int,
  captures: int,
  integrity: float,
  best: int,
  tier: Tier.t,
  pace: float,
  slowed: bool,
  doubled: bool,
}

type actions = {
  mutable start: unit => unit,
  mutable togglePause: unit => unit,
  mutable selectTier: Tier.t => unit,
  mutable selectTheme: Theme.t => unit,
}

let storageKey = (theme: Theme.t, suffix) => `typed:${theme.id}:${suffix}`

let loadBest = (theme, tier: Tier.t) =>
  Dom2.getItem(storageKey(theme, `best:${tier.id}`))
  ->Nullable.toOption
  ->Option.flatMap(Int.fromString(_))
  ->Option.getOr(0)

let loadTier = (theme: Theme.t) =>
  Dom2.getItem(storageKey(theme, "tier"))
  ->Nullable.toOption
  ->Option.flatMap(id => theme.tiers->Tier.find(id))
  ->Option.getOr(Theme.defaultTier(theme))

let freshHud = (theme, ~phase=Title) => {
  let tier = loadTier(theme)
  {
    phase,
    input: "",
    score: 0,
    captures: 0,
    integrity: 1.0,
    best: loadBest(theme, tier),
    tier,
    pace: 1.0,
    slowed: false,
    doubled: false,
  }
}

// Dev-only hooks so browser scripts can read what's falling and summon bonuses.
let exposeDebug: (unit => array<string>, string => unit) => unit = %raw(`(words, bonus) => {
  if (import.meta.env.DEV) Object.assign(window, { __words: words, __bonus: bonus })
}`)

let setDocumentTitle: string => unit = %raw(`title => { document.title = title }`)

let element = (r: React.ref<Nullable.t<Dom.element>>) => r.current->Nullable.toOption

module Kbd = {
  @react.component
  let make = (~children) => <kbd className="kbd"> children </kbd>
}

module TierPicker = {
  @react.component
  let make = (~tiers: array<Tier.t>, ~selected: Tier.t, ~label, ~onSelect) =>
    <div className="models" role="radiogroup" ariaLabel=label>
      {tiers
      ->Array.mapWithIndex((tier, i) => {
        let active = tier.id == selected.id
        <button
          key={tier.id}
          role="radio"
          ariaChecked={active ? #"true" : #"false"}
          className={`models__option${active ? " models__option--active" : ""}`}
          onClick={_ => onSelect(tier)}
        >
          <span className="models__name">
            <Kbd> {Int.toString(i + 1)->React.string} </Kbd>
            {tier.name->React.string}
          </span>
          <span className="models__blurb"> {tier.blurb->React.string} </span>
          <span className="models__multiplier">
            {`${Int.toString(tier.scoreMultiplier)}x score`->React.string}
          </span>
        </button>
      })
      ->React.array}
    </div>
}

module ThemeSwitcher = {
  @react.component
  let make = (~current: Theme.t, ~onSelect) =>
    <div className="themes" role="radiogroup" ariaLabel="Theme">
      {Site.themes
      ->Array.map(theme => {
        let active = theme.id == current.id
        <button
          key={theme.id}
          role="radio"
          ariaChecked={active ? #"true" : #"false"}
          className={`themes__option${active ? " themes__option--active" : ""}`}
          onClick={_ => onSelect(theme)}
        >
          {theme.name->React.string}
        </button>
      })
      ->React.array}
    </div>
}

@react.component
let make = () => {
  let initialTheme = React.useMemo0(() => Site.initialTheme())
  let backdropRef = React.useRef(Nullable.null)
  let windowRef = React.useRef(Nullable.null)
  let fieldRef = React.useRef(Nullable.null)
  let actions = React.useRef({
    start: () => (),
    togglePause: () => (),
    selectTier: _ => (),
    selectTheme: _ => (),
  })
  let (theme, setTheme) = React.useState(() => initialTheme)
  let (hud, setHud) = React.useState(() => freshHud(initialTheme))
  let (audit, setAudit) = React.useState(() => Audit.empty)

  React.useEffect0(() => {
    switch (element(backdropRef), element(windowRef), element(fieldRef)) {
    | (Some(backdrop), Some(win), Some(field)) =>
      let dpr = Math.min(2.0, Dom2.devicePixelRatio)
      field->Canvas2d.setWidth(Float.toInt(Stage.width *. dpr))
      field->Canvas2d.setHeight(Float.toInt(Stage.height *. dpr))
      let fieldCtx = field->Canvas2d.getContext
      let backdropCtx = backdrop->Canvas2d.getContext
      let makeConfig = (theme: Theme.t): Engine.config => {
        width: Stage.width,
        height: Stage.height,
        shieldCells: 44,
        measure: text => theme.look.measure(fieldCtx, text),
        random: Math.random,
        rules: Theme.rules(theme),
      }
      let current = ref(initialTheme)
      let config = ref(makeConfig(initialTheme))
      let tier = ref(loadTier(initialTheme))
      let state = ref(Engine.init(~tier=tier.contents, config.contents))
      let phase = ref(Title)
      let fx = ref(Stage.makeFx())
      let best = ref(loadBest(initialTheme, tier.contents))
      let lastHud = ref(freshHud(initialTheme))
      let lastAuditSeq = ref(0)

      exposeDebug(
        () => state.contents.words->Array.map(word => word.text),
        word =>
          switch current.contents.bonuses->Array.find(b => b.spec.word == word) {
          | Some(b) => state := {...state.contents, bonus: Some({spec: b.spec, x: 0.0, age: 0.0})}
          | None => ()
          },
      )

      let layout = () => {
        let scale = Math.min(
          1.0,
          Math.min(
            (Dom2.innerWidth -. 32.0) /. win->Dom2.offsetWidth,
            (Dom2.innerHeight -. 32.0) /. win->Dom2.offsetHeight,
          ),
        )
        win->Dom2.style->Dom2.setProperty("--scale", Float.toString(scale))
        backdrop->Canvas2d.setWidth(Float.toInt(Dom2.innerWidth *. dpr))
        backdrop->Canvas2d.setHeight(Float.toInt(Dom2.innerHeight *. dpr))
        current.contents.look.makeBackdrop(
          ~width=Dom2.innerWidth,
          ~height=Dom2.innerHeight,
          ~window=win->Dom2.getBoundingClientRect,
        )
      }
      let board = ref(layout())
      let onResize = () => board := layout()

      let toViewport = (word: Engine.word) => {
        let rect = field->Dom2.getBoundingClientRect
        let (cx, cy) = Stage.center(word)
        (
          rect.left +. cx *. rect.width /. Stage.width,
          rect.top +. cy *. rect.height /. Stage.height,
        )
      }

      let handle = events =>
        events->Array.forEach((event: Engine.event) => {
          let theme = current.contents
          fx.contents->Stage.onEvent(theme, event)
          switch event {
          | Captured(word) =>
            theme.sound.capture()
            let (x, y) = toViewport(word)
            board.contents.capture(~x, ~y)
          | BonusCaptured(spec, _) =>
            theme.sound.bonus(spec)
            board.contents.bonus(spec)
          | Missed(_) => theme.sound.miss()
          | Breached(_, cells) => cells > 0 ? theme.sound.breach() : ()
          | Spawned(_) => ()
          }
        })

      let start = () => {
        Synth.unlock()
        state := Engine.init(~tier=tier.contents, config.contents)
        fx := Stage.makeFx()
        phase := Playing
      }
      let togglePause = () =>
        switch phase.contents {
        | Playing => phase := Paused
        | Paused => phase := Playing
        | Title | Over => start()
        }
      let selectTier = next => {
        tier := next
        best := loadBest(current.contents, next)
        Dom2.setItem(storageKey(current.contents, "tier"), next.id)
      }
      let selectTheme = (next: Theme.t) =>
        if next.id != current.contents.id {
          current := next
          config := makeConfig(next)
          tier := loadTier(next)
          best := loadBest(next, tier.contents)
          state := Engine.init(~tier=tier.contents, config.contents)
          fx := Stage.makeFx()
          phase := Title
          board := layout()
          Dom2.setItem(Site.themeKey, next.id)
          setTheme(_ => next)
        }
      actions.current.start = start
      actions.current.togglePause = togglePause
      actions.current.selectTier = selectTier
      actions.current.selectTheme = selectTheme

      let onKey = (e: Dom2.keyboardEvent) =>
        if !(e.metaKey || e.ctrlKey || e.altKey) {
          let tiers = current.contents.tiers
          switch (phase.contents, e.key) {
          | (Title | Over, "Enter") =>
            e->Dom2.preventDefault
            start()
          | (Title | Over, "ArrowLeft" | "ArrowRight") =>
            e->Dom2.preventDefault
            selectTier(tiers->Tier.next(tier.contents, e.key == "ArrowLeft" ? -1 : 1))
          | (Title | Over, key) =>
            switch Int.fromString(key)->Option.flatMap(n => tiers->Array.get(n - 1)) {
            | Some(picked) => selectTier(picked)
            | None => ()
            }
          | (Paused, "Escape" | "Enter") | (Playing, "Escape") => togglePause()
          | (Playing, "Backspace") =>
            e->Dom2.preventDefault
            state := Engine.backspace(state.contents)
          | (Playing, key) if String.length(key) == 1 =>
            e->Dom2.preventDefault
            let (next, events) = state.contents->Engine.typeKey(key)
            state := next
            handle(events)
          | _ => ()
          }
        }
      let onBlur = () => phase.contents == Playing ? phase := Paused : ()

      let syncHud = () => {
        let s = state.contents
        let next = {
          phase: phase.contents,
          input: s.input,
          score: s.score,
          captures: s.captures,
          integrity: Shield.integrity(s.shield),
          best: best.contents,
          tier: phase.contents == Playing || phase.contents == Paused ? s.tier : tier.contents,
          pace: Engine.pace(s),
          slowed: Engine.slowed(s),
          doubled: Engine.doubled(s),
        }
        if next != lastHud.contents {
          lastHud := next
          setHud(_ => next)
        }
        if s.audit.seq != lastAuditSeq.contents {
          lastAuditSeq := s.audit.seq
          setAudit(_ => s.audit)
        }
      }

      let last = ref(Dom2.now())
      let frameId = ref(0)
      let rec frame = time => {
        let dt = Math.min(0.05, (time -. last.contents) /. 1000.0)
        last := time
        if phase.contents == Playing {
          let (next, events) = state.contents->Engine.step(config.contents, dt)
          state := next
          handle(events)
          if next.over {
            phase := Over
            if next.score > best.contents {
              best := next.score
              Dom2.setItem(
                storageKey(current.contents, `best:${next.tier.id}`),
                Int.toString(next.score),
              )
            }
          }
        }
        if phase.contents != Paused {
          fx.contents->Stage.update(dt)
          board.contents.update(dt)
        }
        board.contents.draw(backdropCtx, ~time=time /. 1000.0)
        fieldCtx->Stage.draw(
          ~dpr,
          ~theme=current.contents,
          ~state=state.contents,
          ~fx=fx.contents,
          ~time=time /. 1000.0,
        )
        syncHud()
        frameId := Dom2.requestAnimationFrame(frame)
      }

      Dom2.addKeyListener(onKey)
      Dom2.addListener("resize", onResize)
      Dom2.addListener("blur", onBlur)
      // Re-measure once the web fonts are in, so words fit their art.
      Dom2.fontsReady->Promise.thenResolve(() => onResize())->ignore
      frameId := Dom2.requestAnimationFrame(frame)
      Some(
        () => {
          Dom2.cancelAnimationFrame(frameId.contents)
          Dom2.removeKeyListener(onKey)
          Dom2.removeListener("resize", onResize)
          Dom2.removeListener("blur", onBlur)
        },
      )
    | _ => None
    }
  })

  // A theme switch resets the game; mirror that in the HUD and log.
  React.useEffect1(() => {
    setDocumentTitle(theme.copy.title)
    setHud(_ => freshHud(theme))
    setAudit(_ => Audit.empty)
    None
  }, [theme.id])

  let copy = theme.copy
  let percent = Float.toInt(Math.round(hud.integrity *. 100.0))
  let picker =
    <TierPicker
      tiers=theme.tiers
      selected=hud.tier
      label=copy.tierLabel
      onSelect={t => actions.current.selectTier(t)}
    />
  let overlay = switch hud.phase {
  | Title =>
    <div className="overlay">
      <h1 className="overlay__title"> {copy.title->React.string} </h1>
      {copy.intro}
      picker
      <button className="overlay__cta" onClick={_ => actions.current.start()}>
        {"Start"->React.string}
        <Kbd> {"Enter"->React.string} </Kbd>
      </button>
    </div>
  | Paused =>
    <div className="overlay">
      <h2 className="overlay__heading"> {"Paused"->React.string} </h2>
      <button className="overlay__cta" onClick={_ => actions.current.togglePause()}>
        {"Resume"->React.string}
        <Kbd> {"Esc"->React.string} </Kbd>
      </button>
    </div>
  | Over =>
    <div className="overlay">
      <h2 className="overlay__heading overlay__heading--danger">
        {copy.overHeading->React.string}
      </h2>
      <p className="overlay__copy">
        {copy.overSummary(~captures=hud.captures, ~score=hud.score)->React.string}
      </p>
      picker
      <button className="overlay__cta" onClick={_ => actions.current.start()}>
        {"Try again"->React.string}
        <Kbd> {"Enter"->React.string} </Kbd>
      </button>
    </div>
  | Playing => React.null
  }

  <main className={`scene ${theme.className}`}>
    <canvas className="backdrop" ref={ReactDOM.Ref.domRef(backdropRef)} ariaHidden=true />
    <section className="window" ref={ReactDOM.Ref.domRef(windowRef)}>
      <header className="titlebar">
        {theme.logo}
        <span className="titlebar__name"> {copy.appName->React.string} </span>
        <span className="titlebar__sep"> {"/"->React.string} </span>
        <span className="titlebar__crumb"> {copy.crumb->React.string} </span>
        {Array.length(Site.themes) > 1
          ? <ThemeSwitcher current=theme onSelect={t => actions.current.selectTheme(t)} />
          : React.null}
        <span className="titlebar__hints">
          <Kbd> {"Esc"->React.string} </Kbd>
          {" pause"->React.string}
        </span>
      </header>
      <div className="window__body">
        <div className="playfield">
          <div className="playfield__stage">
            <canvas className="playfield__canvas" ref={ReactDOM.Ref.domRef(fieldRef)} />
            overlay
          </div>
          <footer className="statusbar">
            <div className="stat stat--boundary">
              <span className="stat__label"> {copy.baseLabel->React.string} </span>
              <span className="meter">
                <span
                  className={`meter__fill${percent <= 30 ? " meter__fill--low" : ""}`}
                  style={{width: `${Int.toString(percent)}%`}}
                />
              </span>
              <span className="stat__value"> {`${Int.toString(percent)}%`->React.string} </span>
            </div>
            <div className="prompt">
              <span className="prompt__caret"> {">"->React.string} </span>
              <span className="prompt__input"> {hud.input->React.string} </span>
              <span className="prompt__cursor" />
              {hud.slowed ? <span className="badge"> {"slow"->React.string} </span> : React.null}
              {hud.doubled ? <span className="badge"> {"2x"->React.string} </span> : React.null}
            </div>
            <div className="stat">
              <span className="stat__label"> {copy.tierLabel->React.string} </span>
              <span className="stat__value"> {hud.tier.name->React.string} </span>
              <span className="stat__pace" title="The pace climbs as you go">
                {`${Float.toFixed(hud.pace, ~digits=1)}x`->React.string}
              </span>
            </div>
            <div className="stat">
              <span className="stat__label"> {copy.capturesLabel->React.string} </span>
              <span className="stat__value"> {hud.captures->Int.toString->React.string} </span>
            </div>
            <div className="stat">
              <span className="stat__label"> {"Score"->React.string} </span>
              <span className="stat__value stat__value--accent">
                {hud.score->Int.toString->React.string}
              </span>
            </div>
            <div className="stat">
              <span className="stat__label"> {"Best"->React.string} </span>
              <span className="stat__value">
                {Math.Int.max(hud.best, hud.score)->Int.toString->React.string}
              </span>
            </div>
          </footer>
        </div>
        <AuditLog log=audit copy=copy.log />
      </div>
    </section>
  </main>
}
