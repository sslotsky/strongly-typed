// Generated by BUCKLESCRIPT VERSION 4.0.5, PLEASE EDIT WITH CARE

import * as List from "bs-platform/lib/es6/list.js";
import * as Curry from "bs-platform/lib/es6/curry.js";
import * as $$String from "bs-platform/lib/es6/string.js";
import * as Caml_int32 from "bs-platform/lib/es6/caml_int32.js";
import * as Caml_primitive from "bs-platform/lib/es6/caml_primitive.js";
import * as Audio$StronglyTyped from "./audio.bs.js";
import * as Crash$StronglyTyped from "./crash.bs.js";
import * as ManiconPng from "./assets/manicon.png";
import * as Common$StronglyTyped from "./common.bs.js";
import * as Atari_boomWav from "./assets/atari_boom.wav";
import * as SFX_Pickup_01Wav from "./assets/SFX_Pickup_01.wav";

function calculateWidth(context, str) {
  return context.measureText(str).width;
}

function drawStatusBar(context, ui, state, score) {
  context.fillStyle = "gray";
  context.fillRect(0.0, ui[/* height */0], ui[/* width */1], 40.0);
  context.fillStyle = "black";
  context.fillRect(10.0, ui[/* height */0] + 10.0, 100.0, 40.0 - 20.0);
  var match = state[/* base */3];
  context.fillStyle = "red";
  context.fillRect(10.0, ui[/* height */0] + 10.0, Caml_primitive.caml_float_min(100.0, Curry._2(state[/* crashCollector */4][/* percentCovered */2], match[0], match[1])), 40.0 - 20.0);
  context.font = "20px neuropol x rg";
  var str = Curry._1(ui[/* input */2], /* () */0);
  var inputWidth = context.measureText(str).width;
  var inputLeft = ui[/* width */1] / 2.0 - inputWidth / 2.0;
  if (Curry._1(ui[/* input */2], /* () */0) !== "") {
    context.fillStyle = "black";
    context.fillRect(inputLeft - 5.0, ui[/* height */0] + 5.0, inputWidth + 10.0, 30.0);
  }
  context.fillStyle = "lime";
  context.fillText(Curry._1(ui[/* input */2], /* () */0), inputLeft, ui[/* height */0] + 30.0);
  var str$1 = String(score);
  var width = context.measureText(str$1).width;
  context.fillStyle = "red";
  context.fillText(String(score), ui[/* width */1] - width - 10.0, ui[/* height */0] + 30.0);
  return /* () */0;
}

function splitText(context, text, input, left, bottom, color, matchColor) {
  var match = Common$StronglyTyped.startsWith(text, input);
  var match$1 = input.length;
  var match$2 = text.length;
  var match$3 = match ? /* tuple */[
      input,
      $$String.sub(text, match$1, match$2 - match$1 | 0)
    ] : /* tuple */[
      "",
      text
    ];
  var matching = match$3[0];
  var $$continue = left + context.measureText(matching).width;
  context.fillStyle = matchColor;
  context.fillText(matching, left, bottom);
  context.fillStyle = color;
  context.fillText(match$3[1], $$continue, bottom);
  return /* () */0;
}

function drawBonus(context, bonus, image, ui) {
  context.drawImage(image, bonus[/* x */0], bonus[/* startY */1] + bonus[/* offsetY */2]);
  context.font = "16px neuropol x rg";
  var imageWidth = image.width;
  var imageCenter = bonus[/* x */0] + imageWidth / 2.0;
  var text = "manifold";
  var textWidth = context.measureText(text).width;
  var textLeft = imageCenter - textWidth / 2.0;
  var textBottom = bonus[/* startY */1] + bonus[/* offsetY */2] + image.height + 18.0;
  return splitText(context, text, Curry._1(ui[/* input */2], /* () */0), textLeft, textBottom, "white", "lime");
}

function renderWords(context, state, width, height, input) {
  context.clearRect(0, 0, width | 0, (height | 0) + 40 | 0);
  context.fillStyle = "black";
  context.fillRect(0.0, 0.0, width, height);
  context.font = String(30) + "px neuropol x rg";
  List.iter((function (word) {
          return splitText(context, word[/* text */0], input, word[/* x */2], word[/* y */3], "blue", "red");
        }), state[/* words */1]);
  var match = state[/* base */3];
  var baseLeft = match[0];
  context.fillStyle = "orange";
  context.fillRect(baseLeft, height - 5.0, match[1] - baseLeft, 5.0);
  context.fillStyle = "black";
  return List.iter((function (site) {
                context.fillRect(site[/* left */0], height - 5.0, site[/* right */1] - site[/* left */0], 5.0);
                return /* () */0;
              }), Curry._1(state[/* crashCollector */4][/* sites */3], /* () */0));
}

function paint(param, dimensions, assetConfig, initialState, nextState) {
  var context = param[1];
  var canvas = param[0];
  var bonus = assetConfig[/* bonus */3];
  var audioContext = assetConfig[/* audioContext */2];
  var collectSound = assetConfig[/* collectSound */1];
  var boomSound = assetConfig[/* boomSound */0];
  var width = dimensions[/* width */1];
  var height = dimensions[/* height */0];
  var input = /* record */[/* contents */""];
  var score = /* record */[/* contents */0];
  var paused = /* record */[/* contents */false];
  var clearInput = function () {
    input[0] = "";
    return /* () */0;
  };
  var reset = function () {
    input[0] = "";
    score[0] = 0;
    return /* () */0;
  };
  var playPause = function () {
    paused[0] = !paused[0];
    return /* () */0;
  };
  var keypress = function (e) {
    input[0] = input[0] + e.key;
    return /* () */0;
  };
  var ui_002 = function () {
    return input[0];
  };
  var ui_004 = function (str) {
    context.font = String(30) + "px neuropol x rg";
    return context.measureText(str).width;
  };
  var ui_005 = function () {
    return Audio$StronglyTyped.playSound(audioContext, boomSound);
  };
  var ui_006 = function (word) {
    Audio$StronglyTyped.playSound(audioContext, collectSound);
    score[0] = score[0] + Caml_int32.imul(word[/* text */0].length, 10.0 * word[/* velocity */1] | 0) | 0;
    return /* () */0;
  };
  var ui = /* record */[
    /* height */height,
    /* width */width,
    ui_002,
    /* clearInput */clearInput,
    ui_004,
    ui_005,
    ui_006
  ];
  canvas.addEventListener("click", playPause);
  window.addEventListener("keypress", keypress);
  var tick = function (state) {
    if (state[/* gameOver */0]) {
      var text = "GAME OVER";
      context.font = "90px neuropol x rg";
      context.fillStyle = "purple";
      context.fillText(text, width / 2.0 - context.measureText(text).width / 2.0, height / 2.0);
      canvas.removeEventListener("click", playPause);
      window.removeEventListener("keypress", keypress);
      var restart = function () {
        reset(/* () */0);
        canvas.removeEventListener("click", restart);
        canvas.addEventListener("click", playPause);
        window.addEventListener("keypress", keypress);
        return tick(/* record */[
                    /* gameOver */initialState[/* gameOver */0],
                    /* words */initialState[/* words */1],
                    /* ticks */initialState[/* ticks */2],
                    /* base */initialState[/* base */3],
                    /* crashCollector */Crash$StronglyTyped.crashSite(/* () */0),
                    /* bonus */initialState[/* bonus */5]
                  ]);
      };
      canvas.addEventListener("click", restart);
      return /* () */0;
    } else if (paused[0]) {
      window.requestAnimationFrame((function () {
              return tick(state);
            }));
      return /* () */0;
    } else {
      var newState = Curry._2(nextState, state, ui);
      renderWords(context, newState, width, height, Curry._1(ui_002, /* () */0));
      drawStatusBar(context, ui, newState, score[0]);
      var match = newState[/* bonus */5];
      if (match !== undefined) {
        drawBonus(context, match, bonus, ui);
      }
      window.requestAnimationFrame((function () {
              return tick(newState);
            }));
      return /* () */0;
    }
  };
  return tick(initialState);
}

function boot(canvas, height, width, initialState, nextState) {
  var context = canvas.getContext("2d");
  context.fillStyle = "black";
  context.fillRect(0.0, 0.0, width, height + 40.0);
  var text = "START GAME";
  context.font = "90px neuropol x rg";
  context.fillStyle = "purple";
  context.fillText(text, width / 2.0 - context.measureText(text).width / 2.0, height / 2.0);
  var startGame = function () {
    canvas.removeEventListener("click", startGame);
    var ctx = Audio$StronglyTyped.audioContext(/* () */0);
    var loadBoom = Audio$StronglyTyped.loadSound(ctx, Atari_boomWav.default);
    var loadCollect = Audio$StronglyTyped.loadSound(ctx, SFX_Pickup_01Wav.default);
    var bonus = new Image();
    bonus.onload = (function () {
        loadBoom.then((function (boomSound) {
                return loadCollect.then((function (collectSound) {
                              var partial_arg = /* record */[
                                /* boomSound */boomSound,
                                /* collectSound */collectSound,
                                /* audioContext */ctx,
                                /* bonus */bonus
                              ];
                              var partial_arg$1 = /* record */[
                                /* height */height,
                                /* width */width
                              ];
                              var partial_arg$2 = /* tuple */[
                                canvas,
                                context
                              ];
                              var start = function (param, param$1) {
                                return paint(partial_arg$2, partial_arg$1, partial_arg, param, param$1);
                              };
                              Curry._2(start, initialState, nextState);
                              return Promise.resolve(/* () */0);
                            }));
              }));
        return /* () */0;
      });
    bonus.src = ManiconPng.default;
    return /* () */0;
  };
  canvas.addEventListener("click", startGame);
  return /* () */0;
}

var fontSize = 30;

var baseHeight = 5.0;

var statusBarHeight = 40.0;

export {
  fontSize ,
  calculateWidth ,
  baseHeight ,
  statusBarHeight ,
  drawStatusBar ,
  splitText ,
  drawBonus ,
  renderWords ,
  paint ,
  boot ,
  
}
/* ./assets/manicon.png Not a pure module */
