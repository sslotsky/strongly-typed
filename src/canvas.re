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
[@bs.module "./assets/SFX_Pickup_01.wav"] external collect: string = "default";

let canvas = getCanvas("canvas");
let context = canvas->getContext("2d");

let calculateWidth = str => context->measureText(str)->widthGet;

let baseHeight = 5.0;
let statusBarHeight = 40.0;

type dimensions = {
  height: float,
  width: float,
  fontSize: int
};

type audioConfig = {
  boomSound: Audio.buffer,
  collectSound: Audio.buffer,
  audioContext: Audio.audioContext
};

let drawStatusBar = (ui: ui, newState) => {
  context->fillStyleSet("gray");
  context->fillRect(0.0, ui.height, ui.width, statusBarHeight);

  context->fillStyleSet("black");
  context->fillRect(10.0, ui.height +. 10.0, 100.0, statusBarHeight -. 20.0);

  let (baseLeft, baseRight) = newState.base;
  context->fillStyleSet("red");
  context->fillRect(10.0, ui.height +. 10.0, min(100.0, newState.crashCollector.percentCovered(baseLeft, baseRight)), statusBarHeight -. 20.0);

  context->fontSet("20px Arial");
  let inputWidth = ui.calculateWidth(ui.input());
  let inputLeft = (ui.width /. 2.0) -. (inputWidth /. 2.0);

  if (ui.input() != "") {
    context->fillStyleSet("black");
    context->fillRect(inputLeft -. 5.0, ui.height +. 5.0, inputWidth +. 10.0, 30.0);
  };

  context->fillStyleSet("purple");
  context->fillText(ui.input(), inputLeft, ui.height +. 30.0);

  let width = ui.calculateWidth(ui.score()->string_of_int);
  context->fillStyleSet("red");
  context->fillText(ui.score()->string_of_int, ui.width -. width, ui.height +. 30.0);
};

let paint = (dimensions, audioConfig, initialState, nextState) => {
  let ({width, height, fontSize}, {audioContext, boomSound, collectSound}) = (dimensions, audioConfig);
  let input = ref("");
  let score = ref(0);

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
    score: () => score^,
    onCrash: _ => audioContext->playSound(boomSound),
    onCollect: word => {
      audioContext->playSound(collectSound);
      score := score^ + (word.text->String.length * (10.0 *. word.velocity)->int_of_float);
      Js.log(score);
    }
  };

  let rec tick = state => {
    context->clearRect(0, 0, ui.width->int_of_float, ui.height->int_of_float + statusBarHeight->int_of_float);
    context->fillStyleSet("black");
    context->fillRect(0.0, 0.0, ui.width, ui.height);
    context->fontSet(ui.fontSize->string_of_int ++ "px Arial");

    let newState = state->nextState(ui);

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

    drawStatusBar(ui, newState);

    if (newState.gameOver) {
      let text = "GAME OVER";
      context->fontSet("90px Arial");
      context->fillStyleSet("purple");
      context->fillText(text, (ui.width /. 2.0) -. (ui.calculateWidth(text) /. 2.0), ui.height /. 2.0);

      Js.log(initialState.gameOver);
      let rec restart = _ => {
        canvas->unsubscribe("click", restart);
        { ...initialState, crashCollector: Crash.crashSite() }->tick;
      };

      canvas->subscribe("click", restart);
    } else {
      animate(() => newState->tick);
    };
  };

  initialState->tick;
};

let boot = (height, width, fontSize, initialState, nextState) => {
  context->fillStyleSet("black");
  context->fillRect(0.0, 0.0, width, height +. statusBarHeight);

  let text = "START GAME";
  context->fontSet("90px Arial");
  context->fillStyleSet("purple");
  context->fillText(text, (width /. 2.0) -. (calculateWidth(text) /. 2.0), height /. 2.0);

  let rec startGame = (_) => {
    canvas->unsubscribe("click", startGame);

    let ctx = audioContext();
    let loadBoom = ctx->loadSound(boom);
    let loadCollect = ctx->loadSound(collect);

    loadBoom |> Js.Promise.then_(boomSound => {
      loadCollect |> Js.Promise.then_(collectSound => {
        let start = paint({width, height, fontSize}, {audioContext: ctx, boomSound, collectSound});
        start(initialState, nextState);
        Js.Promise.resolve();
      })
    }) |> ignore;
  };

  canvas->subscribe("click", startGame);
};
