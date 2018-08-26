// Generated by BUCKLESCRIPT VERSION 4.0.3, PLEASE EDIT WITH CARE

import * as List from "bs-platform/lib/es6/list.js";
import * as Curry from "bs-platform/lib/es6/curry.js";
import * as $$String from "bs-platform/lib/es6/string.js";
import * as Caml_int32 from "bs-platform/lib/es6/caml_int32.js";
import * as Caml_primitive from "bs-platform/lib/es6/caml_primitive.js";
import * as Audio$StronglyTyped from "./audio.bs.js";
import * as Crash$StronglyTyped from "./crash.bs.js";
import * as Common$StronglyTyped from "./common.bs.js";
import * as Atari_boomWav from "./assets/atari_boom.wav";
import * as SFX_Pickup_01Wav from "./assets/SFX_Pickup_01.wav";

var canvas = document.getElementById("canvas");

var context = canvas.getContext("2d");

function calculateWidth(str) {
  return context.measureText(str).width;
}

function drawStatusBar(ui, newState) {
  context.fillStyle = "gray";
  context.fillRect(0.0, ui[/* height */1], ui[/* width */2], 40.0);
  context.fillStyle = "black";
  context.fillRect(10.0, ui[/* height */1] + 10.0, 100.0, 40.0 - 20.0);
  var match = newState[/* base */3];
  context.fillStyle = "red";
  context.fillRect(10.0, ui[/* height */1] + 10.0, Caml_primitive.caml_float_min(100.0, Curry._2(newState[/* crashCollector */4][/* percentCovered */2], match[0], match[1])), 40.0 - 20.0);
  context.font = "20px Arial";
  var inputWidth = Curry._1(ui[/* calculateWidth */6], Curry._1(ui[/* input */4], /* () */0));
  var inputLeft = ui[/* width */2] / 2.0 - inputWidth / 2.0;
  if (Curry._1(ui[/* input */4], /* () */0) !== "") {
    context.fillStyle = "black";
    context.fillRect(inputLeft - 5.0, ui[/* height */1] + 5.0, inputWidth + 10.0, 30.0);
  }
  context.fillStyle = "purple";
  context.fillText(Curry._1(ui[/* input */4], /* () */0), inputLeft, ui[/* height */1] + 30.0);
  var width = Curry._1(ui[/* calculateWidth */6], String(Curry._1(ui[/* score */0], /* () */0)));
  context.fillStyle = "red";
  context.fillText(String(Curry._1(ui[/* score */0], /* () */0)), ui[/* width */2] - width, ui[/* height */1] + 30.0);
  return /* () */0;
}

function paint(dimensions, audioConfig, initialState, nextState) {
  var audioContext = audioConfig[/* audioContext */2];
  var collectSound = audioConfig[/* collectSound */1];
  var boomSound = audioConfig[/* boomSound */0];
  var fontSize = dimensions[/* fontSize */2];
  var width = dimensions[/* width */1];
  var height = dimensions[/* height */0];
  var input = /* record */[/* contents */""];
  var score = /* record */[/* contents */0];
  var clearInput = function () {
    input[0] = "";
    return /* () */0;
  };
  window.addEventListener("keypress", (function (e) {
          input[0] = input[0] + e.key;
          return /* () */0;
        }));
  var ui_000 = function () {
    return score[0];
  };
  var ui_004 = function () {
    return input[0];
  };
  var ui_007 = function () {
    return Audio$StronglyTyped.playSound(audioContext, boomSound);
  };
  var ui_008 = function (word) {
    Audio$StronglyTyped.playSound(audioContext, collectSound);
    score[0] = score[0] + Caml_int32.imul(word[/* text */0].length, 10.0 * word[/* velocity */1] | 0) | 0;
    console.log(score);
    return /* () */0;
  };
  var ui = /* record */[
    ui_000,
    /* height */height,
    /* width */width,
    /* fontSize */fontSize,
    ui_004,
    /* clearInput */clearInput,
    /* calculateWidth */calculateWidth,
    ui_007,
    ui_008
  ];
  var tick = function (state) {
    context.clearRect(0, 0, width | 0, (height | 0) + 40 | 0);
    context.fillStyle = "black";
    context.fillRect(0.0, 0.0, width, height);
    context.font = String(fontSize) + "px Arial";
    var newState = Curry._2(nextState, state, ui);
    List.iter((function (word) {
            var input = Curry._1(ui_004, /* () */0);
            var text = word[/* text */0];
            var match = Common$StronglyTyped.startsWith(input, word);
            var match$1 = input.length;
            var match$2 = text.length;
            var match$3 = match ? /* tuple */[
                input,
                $$String.sub(text, match$1, match$2 - match$1 | 0)
              ] : /* tuple */[
                "",
                word[/* text */0]
              ];
            var matching = match$3[0];
            var $$continue = word[/* x */2] + context.measureText(matching).width;
            context.fillStyle = "red";
            context.fillText(matching, word[/* x */2], word[/* y */3]);
            context.fillStyle = "blue";
            context.fillText(match$3[1], $$continue, word[/* y */3]);
            return /* () */0;
          }), newState[/* words */1]);
    var match = state[/* base */3];
    var baseLeft = match[0];
    context.fillStyle = "orange";
    context.fillRect(baseLeft, height - 5.0, match[1] - baseLeft, 5.0);
    context.fillStyle = "black";
    List.iter((function (site) {
            context.fillRect(site[/* left */0], height - 5.0, site[/* right */1] - site[/* left */0], 5.0);
            return /* () */0;
          }), Curry._1(state[/* crashCollector */4][/* sites */3], /* () */0));
    drawStatusBar(ui, newState);
    if (newState[/* gameOver */0]) {
      var text = "GAME OVER";
      context.font = "90px Arial";
      context.fillStyle = "purple";
      context.fillText(text, width / 2.0 - context.measureText(text).width / 2.0, height / 2.0);
      console.log(initialState[/* gameOver */0]);
      var restart = function () {
        canvas.removeEventListener("click", restart);
        return tick(/* record */[
                    /* gameOver */initialState[/* gameOver */0],
                    /* words */initialState[/* words */1],
                    /* ticks */initialState[/* ticks */2],
                    /* base */initialState[/* base */3],
                    /* crashCollector */Crash$StronglyTyped.crashSite(/* () */0)
                  ]);
      };
      canvas.addEventListener("click", restart);
      return /* () */0;
    } else {
      window.requestAnimationFrame((function () {
              return tick(newState);
            }));
      return /* () */0;
    }
  };
  return tick(initialState);
}

function boot(height, width, fontSize, initialState, nextState) {
  context.fillStyle = "black";
  context.fillRect(0.0, 0.0, width, height + 40.0);
  var text = "START GAME";
  context.font = "90px Arial";
  context.fillStyle = "purple";
  context.fillText(text, width / 2.0 - context.measureText(text).width / 2.0, height / 2.0);
  var startGame = function () {
    canvas.removeEventListener("click", startGame);
    var ctx = Audio$StronglyTyped.audioContext(/* () */0);
    var loadBoom = Audio$StronglyTyped.loadSound(ctx, Atari_boomWav.default);
    var loadCollect = Audio$StronglyTyped.loadSound(ctx, SFX_Pickup_01Wav.default);
    loadBoom.then((function (boomSound) {
            return loadCollect.then((function (collectSound) {
                          var partial_arg = /* record */[
                            /* boomSound */boomSound,
                            /* collectSound */collectSound,
                            /* audioContext */ctx
                          ];
                          var partial_arg$1 = /* record */[
                            /* height */height,
                            /* width */width,
                            /* fontSize */fontSize
                          ];
                          var start = function (param, param$1) {
                            return paint(partial_arg$1, partial_arg, param, param$1);
                          };
                          Curry._2(start, initialState, nextState);
                          return Promise.resolve(/* () */0);
                        }));
          }));
    return /* () */0;
  };
  canvas.addEventListener("click", startGame);
  return /* () */0;
}

var baseHeight = 5.0;

var statusBarHeight = 40.0;

export {
  canvas ,
  context ,
  calculateWidth ,
  baseHeight ,
  statusBarHeight ,
  drawStatusBar ,
  paint ,
  boot ,
  
}
/* canvas Not a pure module */
