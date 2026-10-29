open Canvas2d

// Draws `text` with the typed prefix highlighted. Returns whether it matched.
let split = (ctx, ~text, ~input, ~x, ~y, ~color, ~matchColor) => {
  let typed = Engine.isPrefix(input, text) ? String.length(input) : 0
  let head = text->String.slice(~start=0, ~end=typed)
  let tail = text->String.slice(~start=typed)
  ctx->fillStyle(matchColor)
  ctx->fillText(head, x, y)
  ctx->fillStyle(color)
  ctx->fillText(tail, x +. (ctx->measureText(head)).width, y)
  typed > 0
}

let width = (ctx, ~font as f, text) => {
  ctx->font(f)
  (ctx->measureText(text)).width
}
