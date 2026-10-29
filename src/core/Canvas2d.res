type element = Dom.element
type t
type path2d
type gradient

@send external getContext: (element, @as("2d") _) => t = "getContext"
@set external setWidth: (element, int) => unit = "width"
@set external setHeight: (element, int) => unit = "height"
@val @scope("document") external createElement: string => element = "createElement"

@set external fillStyle: (t, string) => unit = "fillStyle"
@set external fillGradient: (t, gradient) => unit = "fillStyle"
@set external strokeStyle: (t, string) => unit = "strokeStyle"
@set external strokeGradient: (t, gradient) => unit = "strokeStyle"
@set external lineWidth: (t, float) => unit = "lineWidth"
@set external lineCap: (t, string) => unit = "lineCap"
@set external lineJoin: (t, string) => unit = "lineJoin"
@set external font: (t, string) => unit = "font"
@set external textBaseline: (t, string) => unit = "textBaseline"
@set external textAlign: (t, string) => unit = "textAlign"
@set external globalAlpha: (t, float) => unit = "globalAlpha"
@set external composite: (t, string) => unit = "globalCompositeOperation"
@set external shadowBlur: (t, float) => unit = "shadowBlur"
@set external shadowColor: (t, string) => unit = "shadowColor"

@send external save: t => unit = "save"
@send external restore: t => unit = "restore"
@send external setTransform: (t, float, float, float, float, float, float) => unit = "setTransform"
@send external translate: (t, float, float) => unit = "translate"
@send external scale: (t, float, float) => unit = "scale"
@send external rotate: (t, float) => unit = "rotate"
@send external clearRect: (t, float, float, float, float) => unit = "clearRect"
@send external fillRect: (t, float, float, float, float) => unit = "fillRect"
@send external strokeRect: (t, float, float, float, float) => unit = "strokeRect"
@send external fillText: (t, string, float, float) => unit = "fillText"
@send external beginPath: t => unit = "beginPath"
@send external closePath: t => unit = "closePath"
@send external moveTo: (t, float, float) => unit = "moveTo"
@send external lineTo: (t, float, float) => unit = "lineTo"
@send external arc: (t, float, float, float, float, float) => unit = "arc"
@send external roundRect: (t, float, float, float, float, float) => unit = "roundRect"
@send external fill: t => unit = "fill"
@send external stroke: t => unit = "stroke"
@send external fillPath: (t, path2d) => unit = "fill"
@send external strokePath: (t, path2d) => unit = "stroke"
@send external drawImage: (t, element, float, float) => unit = "drawImage"
@send external drawImageScaled: (t, element, float, float, float, float) => unit = "drawImage"

type metrics = {width: float}
@send external measureText: (t, string) => metrics = "measureText"

@new external path2d: string => path2d = "Path2D"

@send external linearGradient: (t, float, float, float, float) => gradient = "createLinearGradient"
@send
external radialGradient: (t, float, float, float, float, float, float) => gradient =
  "createRadialGradient"
@send external conicGradient: (t, float, float, float) => gradient = "createConicGradient"
@send external addColorStop: (gradient, float, string) => unit = "addColorStop"

let tau = 2.0 *. Math.Constants.pi

let circle = (ctx, x, y, r) => {
  ctx->beginPath
  ctx->arc(x, y, r, 0.0, tau)
}

// A detached canvas for offscreen compositing.
let offscreen = (~width, ~height) => {
  let el = createElement("canvas")
  el->setWidth(width)
  el->setHeight(height)
  el
}
@set external filter: (t, string) => unit = "filter"
@send external quadraticCurveTo: (t, float, float, float, float) => unit = "quadraticCurveTo"
@send external ellipse: (t, float, float, float, float, float, float, float) => unit = "ellipse"

let oval = (ctx, x, y, rx, ry, rotation) => {
  ctx->beginPath
  ctx->ellipse(x, y, rx, ry, rotation, 0.0, tau)
}

let lerp = (a, b, p) => a +. (b -. a) *. p

// The fractional position of a within repeating periods of length b.
let cycle = (a, b) => a -. b *. Math.floor(a /. b)
