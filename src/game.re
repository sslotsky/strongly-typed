type hot;
type canvas;

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
  mutable input: string
};

type ui = {
  height: float,
  width: float,
  fontSize: int,
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
  calculateWidth: str => context->measureText(str)->widthGet
};

let rec paint = (state: state) => {
  context->clearRect(0, 0, int_of_float(ui.width), int_of_float(ui.height));
  context->fontSet(string_of_int(ui.fontSize) ++ "px Arial");

  let newState = state->nextState(ui);
  let {words, input} = newState;

  List.iter(word => {
    let (matching, rest) = switch(String.sub(word.text, 0, String.length(input))) {
    | s when s == input => (s, String.sub(word.text, String.length(input), String.length(word.text) - String.length(input)))
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
  ticks: 0,
  input: "kub"
};

paint(initialState);