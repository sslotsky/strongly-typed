// The base along the bottom of the playfield: a fixed row of cells.
// A word that reaches it untyped breaches the cells beneath it.
type t = {cells: array<bool>, width: float}

let make = (~cells, ~width) => {cells: Array.make(~length=cells, true), width}

let cellWidth = shield => shield.width /. Int.toFloat(Array.length(shield.cells))

let cellRange = (shield, ~left, ~right) => {
  let size = cellWidth(shield)
  let last = Array.length(shield.cells) - 1
  let first = Math.Int.max(0, Math.Int.min(last, Float.toInt(Math.floor(left /. size))))
  let final = Math.Int.max(0, Math.Int.min(last, Float.toInt(Math.ceil(right /. size)) - 1))
  (first, final)
}

// Returns the new shield and how many intact cells were breached.
let breach = (shield, ~left, ~right) => {
  let (first, final) = shield->cellRange(~left, ~right)
  let breached = ref(0)
  let cells = shield.cells->Array.mapWithIndex((intact, i) =>
    if intact && i >= first && i <= final {
      breached := breached.contents + 1
      false
    } else {
      intact
    }
  )
  ({...shield, cells}, breached.contents)
}

let intactCount = shield => shield.cells->Array.filter(intact => intact)->Array.length

let integrity = shield =>
  Int.toFloat(intactCount(shield)) /. Int.toFloat(Array.length(shield.cells))

let isDown = shield => intactCount(shield) == 0

// Restores up to `count` breached cells, nearest the middle first.
let repair = (shield, count) => {
  let total = Array.length(shield.cells)
  let middle = Int.toFloat(total - 1) /. 2.0
  let order =
    shield.cells
    ->Array.mapWithIndex((intact, i) => (i, intact))
    ->Array.filter(((_, intact)) => !intact)
    ->Array.toSorted(((a, _), (b, _)) =>
      Math.abs(Int.toFloat(a) -. middle) -. Math.abs(Int.toFloat(b) -. middle)
    )
    ->Array.slice(~start=0, ~end=count)
    ->Array.map(((i, _)) => i)
  {
    ...shield,
    cells: shield.cells->Array.mapWithIndex((intact, i) => intact || order->Array.includes(i)),
  }
}
