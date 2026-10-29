// Which of the app's themes this deployment offers: VITE_THEMES=garden,gig
// (every theme the app passes in when unset).
let configured: string = %raw(`import.meta.env.VITE_THEMES ?? ""`)

let available = (all: array<Theme.t>) => {
  let picked =
    configured
    ->String.split(",")
    ->Array.map(String.trim)
    ->Array.filterMap(id => all->Array.find((theme: Theme.t) => theme.id == id))
  Array.length(picked) > 0 ? picked : all
}

let themeKey = "typed:theme"

let queryTheme: unit => Nullable.t<
  string,
> = %raw(`() => new URLSearchParams(window.location.search).get("theme")`)

let find = (themes, id) => themes->Array.find((theme: Theme.t) => theme.id == id)

let initialTheme = themes =>
  switch queryTheme()->Nullable.toOption->Option.flatMap(id => themes->find(id)) {
  | Some(theme) => theme
  | None =>
    Dom2.getItem(themeKey)
    ->Nullable.toOption
    ->Option.flatMap(id => themes->find(id))
    ->Option.getOr(themes->Array.getUnsafe(0))
  }
