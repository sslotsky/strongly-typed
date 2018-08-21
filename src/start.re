open Common;

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
