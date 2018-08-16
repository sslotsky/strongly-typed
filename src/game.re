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
  words: list(word),
  input: string
};

let nextState = state => {
  List.iter(word => {
    word.y = switch(word.y) {
    | n when n > 300.0 => 0.0
    | _ => word.y +. 1.0
    };
  }, state.words);

  state;
}

let canvas = getCanvas("canvas");
let context = canvas->getContext("2d");

let rec paint = (state: state) => {
  context->clearRect(0, 0, 300, 300);
  context->fontSet("30px Arial");

  let newState = state->nextState;
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
  words: [{
    text: "Algolia",
    x: 10.0,
    y: 30.0
  }, {
    text: "Alibaba",
    x: 150.0,
    y: 30.0
  }],
  input: "Al"
};

paint(initialState);