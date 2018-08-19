open Common;

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

[@bs.scope "document"][@bs.val] external getCanvas: string => canvas = "getElementById";
[@bs.scope "window"][@bs.val] external animate: (unit => unit) => unit = "requestAnimationFrame";
[@bs.scope "window"][@bs.val] external listen: (string, event => unit) => unit = "addEventListener";
[@bs.send] external getContext: (canvas, string) => context = "getContext";
[@bs.send] external fillText: (context, string, float, float) => unit = "fillText";
[@bs.send] external fillRect: (context, float, float, float, float) => unit = "fillRect";
[@bs.send] external measureText: (context, string) => measurement = "measureText";
[@bs.send] external clearRect: (context, int, int, int, int) => unit = "clearRect";

type ui = {
  height: float,
  width: float,
  fontSize: int,
  input: unit => string,
  clearInput: unit => unit,
  calculateWidth: string => float
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
let (baseMargin, baseHeight) = (20.0, 5.0);

let rec paint = (state, nextState) => {
  context->clearRect(0, 0, int_of_float(ui.width), int_of_float(ui.height));
  context->fontSet(string_of_int(ui.fontSize) ++ "px Arial");

  let newState = state->nextState(ui);

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
  }, newState.words);

  context->fillStyleSet("orange");
  context->fillRect(baseMargin, ui.height -. baseHeight, ui.width -. baseMargin, baseHeight);

  context->fillStyleSet("white");
  List.iter(site => {
    context->fillRect(site.left, ui.height -. baseHeight, site.right -. site.left, baseHeight);
  }, state.crashSites);

  animate(() => paint(state, nextState));
};