%%raw(`import "@fontsource/jetbrains-mono/400.css"`)
%%raw(`import "@fontsource/jetbrains-mono/600.css"`)
%%raw(`import "@fontsource/jetbrains-mono/700.css"`)
%%raw(`import "@fontsource/fraunces/500.css"`)
%%raw(`import "@fontsource/fraunces/700.css"`)
%%raw(`import "./styles.css"`)

switch ReactDOM.querySelector("#root") {
| Some(root) =>
  ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App themes=Themes.all />)
| None => ()
}
