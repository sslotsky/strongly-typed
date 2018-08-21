open Common;

type hot;

[@bs.deriving abstract]
type parcelModule = {
  hot: option(hot)
};

[@bs.val] external parcelModule: parcelModule = "module";
[@bs.send] external accept: (hot, unit) => unit = "accept";

switch (parcelModule->hotGet) {
| Some(h) => h->accept()
| _ => Js.log("We are not hot")
};

Random.self_init();

let (height, width, fontSize, baseMargin) = (600.0, 600.0, 30, 30.0);
let ui = Canvas.initUi(height, width, fontSize);

let initialState = {
  words: [],
  ticks: 0,
  base: (baseMargin, ui.width -. baseMargin),
  gameOver: false,
  crashCollector: Crash.crashSite()
};

ui->Canvas.paint(initialState, Game.nextState);
