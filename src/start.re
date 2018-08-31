open Common;

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

let (height, width, fontSize, baseMargin) = (600.0, 1200.0, 30, 30.0);

let initialState = {
  words: [],
  ticks: 0,
  base: (baseMargin, width -. baseMargin),
  gameOver: false,
  crashCollector: Crash.crashSite(),
  bonus: None
};

Canvas.boot(height, width, fontSize, initialState, Game.nextState);
