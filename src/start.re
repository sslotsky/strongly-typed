type hot;

[@bs.deriving abstract]
type parcelModule = {
  hot: option(hot)
};

[@bs.val] external parcelModule: parcelModule = "module";
[@bs.send] external accept: (hot, unit => unit) => unit = "accept";


switch (parcelModule->hotGet) {
| Some(h) => h->accept(() => Js.log("sooooo hot right now"))
| _ => ()
};

Random.self_init();

ReactDOMRe.renderToElementWithId(<Play />, "app");