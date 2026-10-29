// Which themes this deployment offers: VITE_THEMES=keycard,garden (all when unset).
let configured: string = %raw(`import.meta.env.VITE_THEMES ?? ""`)

let themes = {
  let picked =
    configured
    ->String.split(",")
    ->Array.map(String.trim)
    ->Array.filterMap(id => Themes.all->Array.find((theme: Theme.t) => theme.id == id))
  Array.length(picked) > 0 ? picked : Themes.all
}

let themeKey = "typed:theme"

let queryTheme: unit => Nullable.t<
  string,
> = %raw(`() => new URLSearchParams(window.location.search).get("theme")`)

let find = id => themes->Array.find((theme: Theme.t) => theme.id == id)

let initialTheme = () =>
  switch queryTheme()->Nullable.toOption->Option.flatMap(find) {
  | Some(theme) => theme
  | None =>
    Dom2.getItem(themeKey)
    ->Nullable.toOption
    ->Option.flatMap(find)
    ->Option.getOr(themes->Array.getUnsafe(0))
  }
