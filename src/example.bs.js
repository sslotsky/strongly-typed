// Generated by BUCKLESCRIPT VERSION 4.0.5, PLEASE EDIT WITH CARE

import * as Block from "bs-platform/lib/es6/block.js";
import * as Curry from "bs-platform/lib/es6/curry.js";
import * as React from "react";
import * as Pervasives from "bs-platform/lib/es6/pervasives.js";
import * as ReasonReact from "reason-react/src/ReasonReact.js";
import * as Js_primitive from "bs-platform/lib/es6/js_primitive.js";
import * as Canvas$StronglyTyped from "./canvas.bs.js";

var component = ReasonReact.reducerComponent("Example");

var style = {
  marginBottom: "1rem",
  width: "600px"
};

function make(exampleState, input, _) {
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
          /* render */(function (self) {
              return React.createElement("canvas", {
                          ref: (function (node) {
                              return Curry._1(self[/* send */3], /* Ready */[(node == null) ? undefined : Js_primitive.some(node)]);
                            }),
                          style: style,
                          height: Pervasives.string_of_float(300.0),
                          width: Pervasives.string_of_float(600.0)
                        });
            }),
          /* initialState */(function () {
              return /* record */[/* initialized */false];
            }),
          /* retainedProps */component[/* retainedProps */11],
          /* reducer */(function (action, state) {
              var canvas = action[0];
              var match = state[/* initialized */0];
              if (canvas !== undefined && !match) {
                var node = Js_primitive.valFromOption(canvas);
                return /* UpdateWithSideEffects */Block.__(2, [
                          /* record */[/* initialized */true],
                          (function () {
                              var context = node.getContext("2d");
                              return Canvas$StronglyTyped.renderWords(context, exampleState, 600.0, 300.0, input);
                            })
                        ]);
              } else {
                return /* NoUpdate */0;
              }
            }),
          /* jsElementWrapped */component[/* jsElementWrapped */13]
        ];
}

var height = 300.0;

var width = 600.0;

export {
  component ,
  height ,
  width ,
  style ,
  make ,
  
}
/* component Not a pure module */