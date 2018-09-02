open Common;
open Audio;

type canvas = Dom.element;

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
type image = {
  mutable onload: unit => unit,
  mutable src: string,
  [@bs.as "width"] imageWidth: int,
  [@bs.as "height"] imageHeight: int,
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
[@bs.send] external drawImage: (context, image, float, float) => unit = "drawImage";
[@bs.new] external createImage: unit => image = "Image";
[@bs.module "./assets/atari_boom.wav"] external boom: string = "default";
[@bs.module "./assets/SFX_Pickup_01.wav"] external collect: string = "default";
[@bs.module "./assets/manicon.png"] external manicon: string = "default";

let fontSize = 30;
let calculateWidth = (context, str) => context->measureText(str)->widthGet;

let baseHeight = 5.0;
let statusBarHeight = 40.0;

type dimensions = {
  height: float,
  width: float,
};

type assetConfig = {
  boomSound: Audio.buffer,
  collectSound: Audio.buffer,
  audioContext: Audio.audioContext,
  bonus: image
};

let drawStatusBar = (context, ui: ui, state, score) => {
  context->fillStyleSet("gray");
  context->fillRect(0.0, ui.height, ui.width, statusBarHeight);

  context->fillStyleSet("black");
  context->fillRect(10.0, ui.height +. 10.0, 100.0, statusBarHeight -. 20.0);

  let (baseLeft, baseRight) = state.base;
  context->fillStyleSet("red");
  context->fillRect(10.0, ui.height +. 10.0, min(100.0, state.crashCollector.percentCovered(baseLeft, baseRight)), statusBarHeight -. 20.0);

  context->fontSet("20px bold arial");
  let inputWidth = context->calculateWidth(ui.input());
  let inputLeft = (ui.width /. 2.0) -. (inputWidth /. 2.0);

  if (ui.input() != "") {
    context->fillStyleSet("black");
    context->fillRect(inputLeft -. 5.0, ui.height +. 5.0, inputWidth +. 10.0, 30.0);
  };

  context->fillStyleSet("lime");
  context->fillText(ui.input(), inputLeft, ui.height +. 30.0);

  let width = context->calculateWidth(score->string_of_int);
  context->fillStyleSet("red");
  context->fillText(score->string_of_int, ui.width -. width -. 10.0, ui.height +. 30.0);
};

let splitText = (context, text, input, left, bottom, color, matchColor) => {
  let (matching, rest) = switch(text->startsWith(input), input->String.length, text->String.length) {
  | (true, inputLength, wordLength) => (input, text->String.sub(inputLength, wordLength - inputLength))
  | _ => ("", text)
  };

  let continue = left +. context->measureText(matching)->widthGet;
  context->fillStyleSet(matchColor);
  context->fillText(matching, left, bottom);
  context->fillStyleSet(color);
  context->fillText(rest, continue, bottom);
};

let drawBonus = (context, bonus: bonus, image, ui) => {
  context->drawImage(image, bonus.x, bonus.startY +. bonus.offsetY);
  context->fontSet("16px arial");

  let imageWidth = image->imageWidthGet;
  let imageCenter = bonus.x +. (imageWidth->float_of_int /. 2.0);
  let text = "manifold";
  let textWidth = context->calculateWidth(text);
  let textLeft = imageCenter -. (textWidth /. 2.0);
  let textBottom = bonus.startY +. bonus.offsetY +. image->imageHeightGet->float_of_int +. 18.0;

  context->splitText(text, ui.input(), textLeft, textBottom, "white", "lime");
};

let renderWords = (context, state, ui: ui) => {
  context->clearRect(0, 0, ui.width->int_of_float, ui.height->int_of_float + statusBarHeight->int_of_float);
  context->fillStyleSet("black");
  context->fillRect(0.0, 0.0, ui.width, ui.height);

  context->fontSet(fontSize->string_of_int ++ "px arial");

  state.words |> List.iter(word => {
    context->splitText(word.text, ui.input(), word.x, word.y, "blue", "red");
  });

  let (baseLeft, baseRight) = state.base;
  context->fillStyleSet("orange");
  context->fillRect(baseLeft, ui.height -. baseHeight, baseRight -. baseLeft, baseHeight);

  context->fillStyleSet("black");
  state.crashCollector.sites() |> List.iter(site => {
    context->fillRect(site.left, ui.height -. baseHeight, site.right -. site.left, baseHeight);
  });
};

let paint = ((canvas, context), dimensions, assetConfig, initialState, nextState) => {
  let ({width, height}, {audioContext, boomSound, collectSound, bonus}) = (dimensions, assetConfig);
  let input = ref("");
  let score = ref(0);
  let paused = ref(false);

  let clearInput = () => {
    input := "";
  };

  listen("keypress", (e) => {
    input := (input^) ++ e->keyGet;
  });

  let reset = () => {
    input := "";
    score := 0;
  };

  let playPause = _ => {
    paused := !paused^;
  };

  let ui = {
    height,
    width,
    input: () => input^,
    clearInput,
    calculateWidth: str => {
      context->fontSet(fontSize->string_of_int ++ "px bold arial");
      context->calculateWidth(str);
    },
    onCrash: _ => audioContext->playSound(boomSound),
    onCollect: word => {
      audioContext->playSound(collectSound);
      score := score^ + (word.text->String.length * (10.0 *. word.velocity)->int_of_float);
    }
  };

  canvas->subscribe("click", playPause);

  let rec tick = state => {
    if (state.gameOver) {
      let text = "GAME OVER";
      context->fontSet("90px bold arial");
      context->fillStyleSet("purple");
      context->fillText(text, (ui.width /. 2.0) -. (context->calculateWidth(text) /. 2.0), ui.height /. 2.0);
      canvas->unsubscribe("click", playPause);

      let rec restart = _ => {
        reset();
        canvas->unsubscribe("click", restart);
        canvas->subscribe("click", playPause);
        { ...initialState, crashCollector: Crash.crashSite() }->tick;
      };

      canvas->subscribe("click", restart);
    } else if (paused^) {
      animate(() => state->tick);
    } else {
      let newState = state->nextState(ui);
      context->renderWords(newState, ui);
      context->drawStatusBar(ui, newState, score^);

      switch (newState.bonus) {
      | None => ()
      | Some(b) => context->drawBonus(b, bonus, ui)
      };

      animate(() => newState->tick);
    };
  };

  initialState->tick;
};

let boot = (canvas, height, width, initialState, nextState) => {
  let context = canvas->getContext("2d");

  context->fillStyleSet("black");
  context->fillRect(0.0, 0.0, width, height +. statusBarHeight);

  let text = "START GAME";
  context->fontSet("90px bold arial");
  context->fillStyleSet("purple");
  context->fillText(text, (width /. 2.0) -. (context->calculateWidth(text) /. 2.0), height /. 2.0);

  let rec startGame = (_) => {
    canvas->unsubscribe("click", startGame);

    let ctx = audioContext();
    let loadBoom = ctx->loadSound(boom);
    let loadCollect = ctx->loadSound(collect);
    let bonus = createImage();

    bonus->onloadSet(() => {
      loadBoom |> Js.Promise.then_(boomSound => {
        loadCollect |> Js.Promise.then_(collectSound => {
          let start = (canvas, context)->paint({width, height}, {audioContext: ctx, boomSound, collectSound, bonus});
          start(initialState, nextState);
          Js.Promise.resolve();
        })
      }) |> ignore;
    });

    bonus->srcSet(manicon);
  };

  canvas->subscribe("click", startGame);
};
