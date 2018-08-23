// Generated by BUCKLESCRIPT VERSION 4.0.3, PLEASE EDIT WITH CARE

import * as Random from "bs-platform/lib/es6/random.js";
import * as Js_primitive from "bs-platform/lib/es6/js_primitive.js";
import * as Game$StronglyTyped from "./game.bs.js";
import * as Crash$StronglyTyped from "./crash.bs.js";
import * as Canvas$StronglyTyped from "./canvas.bs.js";

var match = module.hot;

if (match !== undefined) {
  Js_primitive.valFromOption(match).accept();
} else {
  console.log("We are not hot");
}

Random.self_init(/* () */0);

var initialState = /* record */[
  /* gameOver */false,
  /* words : [] */0,
  /* ticks */0,
  /* base : tuple */[
    30.0,
    600.0 - 30.0
  ],
  /* crashCollector */Crash$StronglyTyped.crashSite(/* () */0)
];

Canvas$StronglyTyped.boot(600.0, 600.0, 30, initialState, Game$StronglyTyped.nextState);

var height = 600.0;

var width = 600.0;

var fontSize = 30;

var baseMargin = 30.0;

export {
  height ,
  width ,
  fontSize ,
  baseMargin ,
  initialState ,
  
}
/* match Not a pure module */
