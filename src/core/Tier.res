// A difficulty tier: the pace a theme offers (winds, tempos...).
type t = {
  id: string,
  name: string,
  blurb: string,
  // Multiplies how fast words fall.
  speed: float,
  // Divides the time between new words.
  requestRate: float,
  scoreMultiplier: int,
}

let standard = {
  id: "standard",
  name: "Standard",
  blurb: "",
  speed: 1.0,
  requestRate: 1.0,
  scoreMultiplier: 1,
}

let find = (tiers, id) => tiers->Array.find(tier => tier.id == id)

let next = (tiers, tier, step) => {
  let count = Array.length(tiers)
  let index = Math.Int.max(0, tiers->Array.findIndex(t => t.id == tier.id))
  tiers->Array.getUnsafe(mod(mod(index + step, count) + count, count))
}
