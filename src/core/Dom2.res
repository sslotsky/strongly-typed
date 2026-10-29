// The few browser APIs the game touches.
type rect = {left: float, top: float, width: float, height: float, right: float, bottom: float}

@send external getBoundingClientRect: Dom.element => rect = "getBoundingClientRect"
@val @scope("window") external devicePixelRatio: float = "devicePixelRatio"
@val @scope("window") external innerWidth: float = "innerWidth"
@val @scope("window") external innerHeight: float = "innerHeight"
@val external requestAnimationFrame: (float => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"
@val @scope("performance") external now: unit => float = "now"

type keyboardEvent = {key: string, metaKey: bool, ctrlKey: bool, altKey: bool}
@send external preventDefault: keyboardEvent => unit = "preventDefault"

@val @scope("window")
external addKeyListener: (@as("keydown") _, keyboardEvent => unit) => unit = "addEventListener"
@val @scope("window")
external removeKeyListener: (@as("keydown") _, keyboardEvent => unit) => unit =
  "removeEventListener"
@val @scope("window")
external addListener: (string, unit => unit) => unit = "addEventListener"
@val @scope("window")
external removeListener: (string, unit => unit) => unit = "removeEventListener"

@val @scope(("document", "fonts")) external fontsReady: promise<unit> = "ready"

type style
@get external style: Dom.element => style = "style"
@send external setProperty: (style, string, string) => unit = "setProperty"
@get external offsetWidth: Dom.element => float = "offsetWidth"
@get external offsetHeight: Dom.element => float = "offsetHeight"
@set external setStyleWidth: (style, string) => unit = "width"
@set external setStyleHeight: (style, string) => unit = "height"

@val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"
