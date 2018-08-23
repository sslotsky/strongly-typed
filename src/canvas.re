open Common;
open Audio;

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
[@bs.send] external subscribe: (canvas, string, event => unit) => unit = "addEventListener";
[@bs.send] external unsubscribe: (canvas, string, event => unit) => unit = "removeEventListener";
[@bs.send] external getContext: (canvas, string) => context = "getContext";
[@bs.send] external fillText: (context, string, float, float) => unit = "fillText";
[@bs.send] external fillRect: (context, float, float, float, float) => unit = "fillRect";
[@bs.send] external measureText: (context, string) => measurement = "measureText";
[@bs.send] external clearRect: (context, int, int, int, int) => unit = "clearRect";
[@bs.module "./assets/atari_boom.wav"] external boom: string = "default";

let canvas = getCanvas("canvas");
let context = canvas->getContext("2d");

let calculateWidth = str => context->measureText(str)->widthGet;

let baseHeight = 5.0;

let paint = (width, height, fontSize, state, nextState, ctx, boomSound) => {
  let input = ref("");

  let clearInput = () => {
    input := "";
  };

  listen("keypress", (e) => {
    input := (input^) ++ e->keyGet;
  });

  let ui = {
    height,
    width,
    fontSize,
    input: () => input^,
    clearInput,
    calculateWidth,
    onCrash: _ => {
      let source = ctx->createBufferSource();
      source->bufferSet(boomSound);
      source->connect(ctx->destinationGet);
      source->start(0);
    }
  };

  let rec tick = state => {
    context->clearRect(0, 0, ui.width->int_of_float, ui.height->int_of_float);
    context->fillStyleSet("black");
    context->fillRect(0.0, 0.0, ui.width, ui.height);

    let newState = state->nextState(ui);

    context->fontSet(ui.fontSize->string_of_int ++ "px Arial");

    List.iter(word => {
      let (input, text) = (ui.input(), word.text);

      let (matching, rest) = switch(input->startsWith(word), input->String.length, text->String.length) {
      | (true, inputLength, wordLength) => (input, text->String.sub(inputLength, wordLength - inputLength))
      | _ => ("", word.text)
      };

      let continue = word.x +. context->measureText(matching)->widthGet;
      context->fillStyleSet("red");
      context->fillText(matching, word.x, word.y);
      context->fillStyleSet("blue");
      context->fillText(rest, continue, word.y);
    }, newState.words);

    let (baseLeft, baseRight) = state.base;
    context->fillStyleSet("orange");
    context->fillRect(baseLeft, ui.height -. baseHeight, baseRight -. baseLeft, baseHeight);

    context->fillStyleSet("black");
    List.iter(site => {
      context->fillRect(site.left, ui.height -. baseHeight, site.right -. site.left, baseHeight);
    }, state.crashCollector.sites());

    if (newState.gameOver) {
      let text = "GAME OVER";
      context->fontSet("90px Arial");
      context->fillStyleSet("purple");
      context->fillText(text, (ui.width /. 2.0) -. (ui.calculateWidth(text) /. 2.0), ui.height /. 2.0);
    } else {
      animate(() => state->tick);
    };
  };

  state->tick;
};

let boot = (height, width, fontSize, initialState, nextState) => {
  context->fillStyleSet("black");
  context->fillRect(0.0, 0.0, width, height);

  let text = "START GAME";
  context->fontSet("90px Arial");
  context->fillStyleSet("purple");
  context->fillText(text, (width /. 2.0) -. (calculateWidth(text) /. 2.0), height /. 2.0);

  let rec startGame = (_) => {
    canvas->unsubscribe("click", startGame);

    let ctx = audioContext();
    ctx->loadSound(boom)|>Js.Promise.then_(boomSound => {
      paint(width, height, fontSize, initialState, nextState, ctx, boomSound);
      Js.Promise.resolve(boomSound);
    })|>ignore;
  };

  canvas->subscribe("click", startGame);
};
