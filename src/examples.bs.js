// Generated by BUCKLESCRIPT VERSION 4.0.5, PLEASE EDIT WITH CARE

import * as $$Array from "bs-platform/lib/es6/array.js";
import * as Curry from "bs-platform/lib/es6/curry.js";
import * as React from "react";
import * as ReasonReact from "reason-react/src/ReasonReact.js";
import * as Crash$StronglyTyped from "./crash.bs.js";
import * as Example$StronglyTyped from "./example.bs.js";

var component = ReasonReact.statelessComponent("Examples");

function $$static(words) {
  return /* record */[
          /* gameOver */false,
          /* words */words,
          /* ticks */0,
          /* base : tuple */[
            0.0,
            600.0
          ],
          /* crashCollector */Crash$StronglyTyped.crashSite(/* () */0),
          /* bonus */undefined
        ];
}

var example1 = $$static(/* :: */[
      /* record */[
        /* text */"Bungalo Bill",
        /* velocity */0.0,
        /* x */120.0,
        /* y */265.0
      ],
      /* :: */[
        /* record */[
          /* text */"Barnacles",
          /* velocity */0.0,
          /* x */20.0,
          /* y */45.0
        ],
        /* :: */[
          /* record */[
            /* text */"Snuffleupagus",
            /* velocity */0.0,
            /* x */290.0,
            /* y */120.0
          ],
          /* [] */0
        ]
      ]
    ]);

var example2 = $$static(/* :: */[
      /* record */[
        /* text */"Scalawags",
        /* velocity */0.0,
        /* x */300.0,
        /* y */150.0
      ],
      /* :: */[
        /* record */[
          /* text */"Marsupial Madness",
          /* velocity */0.0,
          /* x */80.0,
          /* y */70.0
        ],
        /* [] */0
      ]
    ]);

Curry._1(example2[/* crashCollector */4][/* crash */0], /* record */[
      /* left */260.0,
      /* right */315.0
    ]);

var example3 = $$static(/* :: */[
      /* record */[
        /* text */"Rocking the Casbah",
        /* velocity */0.0,
        /* x */120.0,
        /* y */265.0
      ],
      /* :: */[
        /* record */[
          /* text */"Shindig",
          /* velocity */0.0,
          /* x */160.0,
          /* y */200.0
        ],
        /* [] */0
      ]
    ]);

Curry._1(example3[/* crashCollector */4][/* crash */0], /* record */[
      /* left */260.0,
      /* right */315.0
    ]);

Curry._1(example3[/* crashCollector */4][/* crash */0], /* record */[
      /* left */520.0,
      /* right */550.0
    ]);

var example4 = $$static(/* :: */[
      /* record */[
        /* text */"Neologisms",
        /* velocity */0.0,
        /* x */110.0,
        /* y */285.0
      ],
      /* [] */0
    ]);

Curry._1(example4[/* crashCollector */4][/* crash */0], /* record */[
      /* left */100.0,
      /* right */130.0
    ]);

Curry._1(example4[/* crashCollector */4][/* crash */0], /* record */[
      /* left */260.0,
      /* right */315.0
    ]);

Curry._1(example4[/* crashCollector */4][/* crash */0], /* record */[
      /* left */325.0,
      /* right */400.0
    ]);

Curry._1(example4[/* crashCollector */4][/* crash */0], /* record */[
      /* left */500.0,
      /* right */550.0
    ]);

var examples = /* array */[
  /* tuple */[
    example1,
    "Bungalo B"
  ],
  /* tuple */[
    example2,
    "Scala"
  ],
  /* tuple */[
    example3,
    "Roc"
  ],
  /* tuple */[
    example4,
    "Neo"
  ]
];

var style = {
  display: "flex",
  flexDirection: "column"
};

function make() {
  return /* record */[
          /* debugName */component[/* debugName */0],
          /* reactClassInternal */component[/* reactClassInternal */1],
          /* handedOffState */component[/* handedOffState */2],
          /* willReceiveProps */component[/* willReceiveProps */3],
          /* didMount */component[/* didMount */4],
          /* didUpdate */component[/* didUpdate */5],
          /* willUnmount */component[/* willUnmount */6],
          /* willUpdate */component[/* willUpdate */7],
          /* shouldUpdate */component[/* shouldUpdate */8],
          /* render */(function () {
              return React.createElement(React.Fragment, undefined, React.createElement("h1", undefined, "Examples"), React.createElement("div", {
                              style: style
                            }, $$Array.mapi((function (i, param) {
                                    var anchor = "example-" + String(i);
                                    return React.createElement("a", {
                                                key: String(i),
                                                id: anchor,
                                                href: "#" + anchor
                                              }, ReasonReact.element(undefined, undefined, Example$StronglyTyped.make(param[0], param[1], /* array */[])));
                                  }), examples)));
            }),
          /* initialState */component[/* initialState */10],
          /* retainedProps */component[/* retainedProps */11],
          /* reducer */component[/* reducer */12],
          /* jsElementWrapped */component[/* jsElementWrapped */13]
        ];
}

export {
  component ,
  $$static ,
  example1 ,
  example2 ,
  example3 ,
  example4 ,
  examples ,
  style ,
  make ,
  
}
/* component Not a pure module */
