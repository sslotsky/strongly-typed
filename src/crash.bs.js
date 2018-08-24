// Generated by BUCKLESCRIPT VERSION 4.0.3, PLEASE EDIT WITH CARE

import * as List from "bs-platform/lib/es6/list.js";
import * as Js_exn from "bs-platform/lib/es6/js_exn.js";
import * as Caml_primitive from "bs-platform/lib/es6/caml_primitive.js";
import * as Caml_builtin_exceptions from "bs-platform/lib/es6/caml_builtin_exceptions.js";

function crashSite() {
  var sites = /* record */[/* contents : [] */0];
  var crash = function (site) {
    var match = List.partition((function (s) {
            return s[/* left */0] <= site[/* left */0];
          }), sites[0]);
    var rightSide = match[1];
    var leftSide = match[0];
    var rightSide$1;
    if (rightSide) {
      var rest = rightSide[1];
      var s = rightSide[0];
      var exit = 0;
      if (rest || site[/* right */1] < s[/* left */0]) {
        exit = 1;
      } else {
        rightSide$1 = /* :: */[
          /* record */[
            /* left */site[/* left */0],
            /* right */Caml_primitive.caml_float_max(site[/* right */1], s[/* right */1])
          ],
          /* [] */0
        ];
      }
      if (exit === 1) {
        rightSide$1 = site[/* right */1] >= s[/* left */0] ? List.append(/* :: */[
                /* record */[
                  /* left */site[/* left */0],
                  /* right */Caml_primitive.caml_float_max(site[/* right */1], s[/* right */1])
                ],
                /* [] */0
              ], rest) : /* :: */[
            site,
            rightSide
          ];
      }
      
    } else {
      rightSide$1 = /* :: */[
        site,
        rightSide
      ];
    }
    var site$1 = List.hd(rightSide$1);
    var match$1 = List.rev(leftSide);
    var leftSide$1;
    if (match$1) {
      var rest$1 = match$1[1];
      var s$1 = match$1[0];
      var exit$1 = 0;
      if (rest$1 || s$1[/* right */1] < site$1[/* left */0]) {
        exit$1 = 1;
      } else {
        leftSide$1 = /* :: */[
          /* record */[
            /* left */s$1[/* left */0],
            /* right */Caml_primitive.caml_float_max(site$1[/* right */1], s$1[/* right */1])
          ],
          /* [] */0
        ];
      }
      if (exit$1 === 1) {
        leftSide$1 = s$1[/* right */1] >= site$1[/* left */0] ? List.append(List.rev(rest$1), /* :: */[
                /* record */[
                  /* left */s$1[/* left */0],
                  /* right */Caml_primitive.caml_float_max(site$1[/* right */1], s$1[/* right */1])
                ],
                /* [] */0
              ]) : List.append(leftSide, /* :: */[
                site$1,
                /* [] */0
              ]);
      }
      
    } else {
      leftSide$1 = List.append(leftSide, /* :: */[
            site$1,
            /* [] */0
          ]);
    }
    var tmp;
    var exit$2 = 0;
    var tail;
    try {
      tail = List.tl(rightSide$1);
      exit$2 = 1;
    }
    catch (raw_exn){
      var exn = Js_exn.internalToOCamlException(raw_exn);
      if (exn[0] === Caml_builtin_exceptions.failure) {
        tmp = leftSide$1;
      } else {
        throw exn;
      }
    }
    if (exit$2 === 1) {
      tmp = List.append(leftSide$1, tail);
    }
    sites[0] = tmp;
    return /* () */0;
  };
  var covers = function (x, y) {
    return List.exists((function (site) {
                  if (site[/* left */0] <= x) {
                    return site[/* right */1] >= y;
                  } else {
                    return false;
                  }
                }), sites[0]);
  };
  var percentCovered = function (x, y) {
    var x$1 = x < y ? x : y;
    var y$1 = x > y ? x : y;
    var amountCovered = List.fold_left((function (sum, site) {
            return sum + (Caml_primitive.caml_float_min(site[/* right */1], y$1) - Caml_primitive.caml_float_max(site[/* left */0], x$1));
          }), 0.0, sites[0]);
    return 100.0 * amountCovered / (y$1 - x$1);
  };
  return /* record */[
          /* crash */crash,
          /* covers */covers,
          /* percentCovered */percentCovered,
          /* sites */(function () {
              return sites[0];
            })
        ];
}

export {
  crashSite ,
  
}
/* No side effect */