// Generated by BUCKLESCRIPT VERSION 4.0.3, PLEASE EDIT WITH CARE
'use strict';

var List = require("bs-platform/lib/js/list.js");
var Curry = require("bs-platform/lib/js/curry.js");
var Random = require("bs-platform/lib/js/random.js");
var $$String = require("bs-platform/lib/js/string.js");
var Caml_obj = require("bs-platform/lib/js/caml_obj.js");
var Js_primitive = require("bs-platform/lib/js/js_primitive.js");

var match = module.hot;

if (match !== undefined) {
  Js_primitive.valFromOption(match).accept();
} else {
  console.log("We are not hot");
}

var words = /* :: */[
  "Logging",
  /* :: */[
    "Memory Store",
    /* :: */[
      "postgresql",
      /* :: */[
        "kubernetes",
        /* :: */[
          "terraform",
          /* [] */0
        ]
      ]
    ]
  ]
];

function nextState(state, ui) {
  List.iter((function (word) {
          if (word[/* y */2] > ui[/* height */0]) {
            state[/* words */0] = List.filter((function (w) {
                      return Caml_obj.caml_notequal(w, word);
                    }))(state[/* words */0]);
            return /* () */0;
          } else {
            word[2] += 1.0;
            return /* () */0;
          }
        }), state[/* words */0]);
  if (state[/* ticks */1] % 90 === 0) {
    var word = List.nth(words, Random.$$int(List.length(words) - 1 | 0));
    var max = ui[/* width */1] - Curry._1(ui[/* calculateWidth */3], word);
    var x = Random.$$float(max);
    state[/* words */0] = List.append(state[/* words */0], /* :: */[
          /* record */[
            /* text */word,
            /* x */x,
            /* y */ui[/* fontSize */2]
          ],
          /* [] */0
        ]);
  }
  state[/* ticks */1] = state[/* ticks */1] + 1 | 0;
  return state;
}

var canvas = document.getElementById("canvas");

var context = canvas.getContext("2d");

function ui_003(str) {
  return context.measureText(str).width;
}

var ui = /* record */[
  /* height */600.0,
  /* width */600.0,
  /* fontSize */30,
  ui_003
];

function paint(state) {
  context.clearRect(0, 0, 600, 600);
  context.font = String(30) + "px Arial";
  var newState = nextState(state, ui);
  var words = newState[/* words */0];
  var input = newState[/* input */2];
  List.iter((function (word) {
          var s = $$String.sub(word[/* text */0], 0, input.length);
          var match = s === input ? /* tuple */[
              s,
              $$String.sub(word[/* text */0], input.length, word[/* text */0].length - input.length | 0)
            ] : /* tuple */[
              "",
              word[/* text */0]
            ];
          var matching = match[0];
          var $$continue = word[/* x */1] + context.measureText(matching).width;
          context.fillStyle = "red";
          context.fillText(matching, word[/* x */1], word[/* y */2]);
          context.fillStyle = "blue";
          context.fillText(match[1], $$continue, word[/* y */2]);
          return /* () */0;
        }), words);
  window.requestAnimationFrame((function () {
          return paint(state);
        }));
  return /* () */0;
}

var initialState = /* record */[
  /* words : [] */0,
  /* ticks */0,
  /* input */"kub"
];

paint(initialState);

exports.words = words;
exports.nextState = nextState;
exports.canvas = canvas;
exports.context = context;
exports.ui = ui;
exports.paint = paint;
exports.initialState = initialState;
/* match Not a pure module */
