type hot;
type canvas;

[@bs.deriving abstract]
type event = {
  key: string
};

[@bs.deriving abstract]
type context = {
  mutable font: string,
  mutable fillStyle: string 
};

[@bs.deriving abstract]
type measurement = {
  width: float
};

[@bs.deriving abstract]
type parcelModule = {
  hot: option(hot)
};

[@bs.val] external parcelModule: parcelModule = "module";
[@bs.send] external accept: (hot, unit) => unit = "accept";
[@bs.scope "document"][@bs.val] external getCanvas: string => canvas = "getElementById";
[@bs.scope "window"][@bs.val] external animate: (unit => unit) => unit = "requestAnimationFrame";
[@bs.scope "window"][@bs.val] external listen: (string, event => unit) => unit = "addEventListener";
[@bs.send] external getContext: (canvas, string) => context = "getContext";
[@bs.send] external fillText: (context, string, float, float) => unit = "fillText";
[@bs.send] external measureText: (context, string) => measurement = "measureText";
[@bs.send] external clearRect: (context, int, int, int, int) => unit = "clearRect";

switch (parcelModule->hotGet) {
| Some(h) => h->accept()
| _ => Js.log("We are not hot")
};


type word = {
  text: string,
  mutable x: float,
  mutable y: float
};

type state = {
  mutable words: list(word),
  mutable ticks: int,
};

type ui = {
  height: float,
  width: float,
  fontSize: int,
  mutable input: string,
  calculateWidth: string => float
};

let words = ["Logging", "Memory Store", "postgresql", "kubernetes", "terraform"];

let nextState = (state, ui) => {
  List.iter(word => {
    if (word.y > ui.height) {
      state.words = List.filter(w => w != word, state.words);
    } else {
      word.y = word.y +. 1.0;
    };
  }, state.words);

  if (state.ticks mod 90 == 0) {
    let word = List.nth(words, Random.int(List.length(words) - 1));
    let max = ui.width -. ui.calculateWidth(word);
    let x = Random.float(max);
    state.words = List.append(state.words, [{ text: word, x, y: float_of_int(ui.fontSize) }]);
  };

  state.ticks = state.ticks + 1;
  state;
};

let canvas = getCanvas("canvas");
let context = canvas->getContext("2d");
let ui = {
  height: 600.0,
  width: 600.0,
  fontSize: 30,
  input: "",
  calculateWidth: str => context->measureText(str)->widthGet
};

listen("keypress", (e) => {
  ui.input = ui.input ++ e->keyGet;
  Js.log(ui.input);
});

let rec paint = (state) => {
  context->clearRect(0, 0, int_of_float(ui.width), int_of_float(ui.height));
  context->fontSet(string_of_int(ui.fontSize) ++ "px Arial");

  let newState = state->nextState(ui);
  let {words} = newState;

  List.iter(word => {
    let (matching, rest) = switch(word.text, String.length(ui.input)) {
    | (text, length) when length > String.length(text) => ("", word.text)
    | (text, length) when String.sub(text, 0, length) == ui.input => (ui.input, String.sub(text, length, String.length(text) - length))
    | _ => ("", word.text)
    };

    let continue = word.x +. context->measureText(matching)->widthGet;
    context->fillStyleSet("red");
    context->fillText(matching, word.x, word.y);
    context->fillStyleSet("blue");
    context->fillText(rest, continue, word.y);
  }, words);


  animate(() => paint(state));
};

let initialState = {
  words: [],
  ticks: 0
};

paint(initialState);