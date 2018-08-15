type hot;
type canvas;

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
type parcelModule = {
  hot: option(hot)
};

[@bs.val] external parcelModule: parcelModule = "module";
[@bs.send] external accept: (hot, unit) => unit = "accept";
[@bs.scope "document"][@bs.val] external getCanvas: string => canvas = "getElementById";
[@bs.send] external getContext: (canvas, string) => context = "getContext";
[@bs.send] external fillText: (context, string, float, float) => unit = "fillText";
[@bs.send] external measureText: (context, string) => measurement = "measureText";
[@bs.send] external clearRect: (context, int, int, int, int) => unit = "clearRect";

switch (parcelModule->hotGet) {
| Some(h) => h->accept()
| _ => Js.log("We are not hot")
};


let canvas = getCanvas("canvas");
Js.log(canvas);

let context = canvas->getContext("2d");
Js.log(context);

context->clearRect(0, 0, 300, 300);
context->fontSet("30px Arial");
let start = 10.0;
let continue = start +. context->measureText("Algol")->widthGet;
context->fillStyleSet("red");
context->fillText("Algol", start, 30.0);
context->fillStyleSet("blue");
context->fillText("ia", continue, 30.0);