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
  input: unit => string,
  clearInput: unit => unit,
  calculateWidth: string => float
};

let words = ["Logging", "Memory Store", "postgresql", "kubernetes", "terraform"];

let startsWith = (input, word) => Js.Re.test(word.text, Js.Re.fromString("^" ++ input));

let nextState = (state, ui) => {
  let (captured, falling) = List.partition(w => w.text == ui.input(), state.words);
  let (crashed, remaining) = List.partition(w => w.y > ui.height, falling);

  if (List.length(captured) > 0 || !List.exists(startsWith(ui.input()), remaining)) {
    ui.clearInput();
  };

  List.iter(word => {
    if (word->List.mem(captured) || word->List.mem(crashed)) {
      state.words = List.filter(w => w != word, state.words);
    } else {
      word.y = word.y +. 1.0;
    };
  }, state.words);

  if (state.ticks mod 90 == 0) {
    let word = List.nth(words, Random.int(List.length(words) - 1));
    let max = ui.width -. ui.calculateWidth(word);
    state.words = List.append(state.words, [{ text: word, x: Random.float(max), y: float_of_int(ui.fontSize) }]);
  };

  state.ticks = state.ticks + 1;
  state;
};

let canvas = getCanvas("canvas");
let context = canvas->getContext("2d");

let initUi = (height, width, fontSize) => {
  let input = ref("");

  let clearInput = () => {
    input := "";
  };

  listen("keypress", (e) => {
    input := (input^) ++ e->keyGet;
  });

  {
    height,
    width,
    fontSize,
    input: () => input^,
    clearInput,
    calculateWidth: str => context->measureText(str)->widthGet
  };

};

let ui = initUi(600.0, 600.0, 30);

let rec paint = (state) => {
  context->clearRect(0, 0, int_of_float(ui.width), int_of_float(ui.height));
  context->fontSet(string_of_int(ui.fontSize) ++ "px Arial");

  let newState = state->nextState(ui);
  let {words} = newState;

  List.iter(word => {
    let (matching, rest) = switch(startsWith(ui.input(), word), String.length(ui.input()), String.length(word.text)) {
    | (true, inputLength, wordLength) => (ui.input(), String.sub(word.text, inputLength, wordLength - inputLength))
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