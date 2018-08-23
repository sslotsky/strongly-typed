// Generated by BUCKLESCRIPT VERSION 4.0.3, PLEASE EDIT WITH CARE

import * as List from "bs-platform/lib/es6/list.js";
import * as Curry from "bs-platform/lib/es6/curry.js";
import * as Random from "bs-platform/lib/es6/random.js";
import * as Common$StronglyTyped from "./common.bs.js";

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
          /* :: */[
            "mysql",
            /* :: */[
              "serverless",
              /* :: */[
                "containerization",
                /* :: */[
                  "scalability",
                  /* :: */[
                    "Redis",
                    /* :: */[
                      "RabbitMQ",
                      /* :: */[
                        "machine learning",
                        /* :: */[
                          "analytics",
                          /* :: */[
                            "Optimization",
                            /* :: */[
                              "CMS",
                              /* :: */[
                                "Elastic",
                                /* :: */[
                                  "Algolia",
                                  /* :: */[
                                    "Jaws",
                                    /* :: */[
                                      "Timber",
                                      /* :: */[
                                        "Iron",
                                        /* :: */[
                                          "Piio",
                                          /* [] */0
                                        ]
                                      ]
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]
];

function nextState(state, ui) {
  if (!state[/* gameOver */0]) {
    var match = List.partition((function (w) {
            return w[/* text */0] === Curry._1(ui[/* input */3], /* () */0);
          }), state[/* words */1]);
    var captured = match[0];
    var match$1 = List.partition((function (w) {
            return w[/* y */3] > ui[/* height */0];
          }), match[1]);
    var crashed = match$1[0];
    var tmp = true;
    if (List.length(captured) <= 0) {
      var partial_arg = Curry._1(ui[/* input */3], /* () */0);
      tmp = !List.exists((function (param) {
              return Common$StronglyTyped.startsWith(partial_arg, param);
            }), match$1[1]);
    }
    if (tmp) {
      Curry._1(ui[/* clearInput */4], /* () */0);
    }
    state[/* words */1] = List.fold_left((function (words, word) {
            if (List.mem(word, captured) || List.mem(word, crashed)) {
              return words;
            } else {
              word[3] += word[/* velocity */1];
              return List.append(words, /* :: */[
                          word,
                          /* [] */0
                        ]);
            }
          }), /* [] */0, state[/* words */1]);
    List.iter((function (word) {
            var left = word[/* x */2];
            var right = word[/* x */2] + Curry._1(ui[/* calculateWidth */5], word[/* text */0]);
            if (!Curry._2(state[/* crashCollector */4][/* covers */1], left, right)) {
              Curry._1(ui[/* onCrash */6], word);
            }
            return Curry._1(state[/* crashCollector */4][/* crash */0], /* record */[
                        /* left */left,
                        /* right */right
                      ]);
          }), crashed);
    if (state[/* ticks */2] % 90 === 0) {
      var word = List.nth(words, Random.$$int(List.length(words) - 1 | 0));
      var max = ui[/* width */1] - Curry._1(ui[/* calculateWidth */5], word);
      state[/* words */1] = List.append(state[/* words */1], /* :: */[
            /* record */[
              /* text */word,
              /* velocity */1.0 + Random.$$float(2.5),
              /* x */Random.$$float(max),
              /* y */ui[/* fontSize */2]
            ],
            /* [] */0
          ]);
    }
    state[/* ticks */2] = state[/* ticks */2] + 1 | 0;
    if (Curry._2(state[/* crashCollector */4][/* covers */1], 30.0, 570.0)) {
      state[/* gameOver */0] = true;
    }
    
  }
  return state;
}

export {
  words ,
  nextState ,
  
}
/* No side effect */
