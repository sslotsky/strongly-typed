type hot;


[@bs.deriving abstract]
type parcelModule = {
  hot: option(hot)
};

[@bs.val] external parcelModule: parcelModule = "module";
[@bs.send] external accept: (hot, unit) => unit = "accept";

switch (parcelModule->hotGet) {
| Some(h) => h->accept()
| _ => Js.log("We are not hot")
};

Js.log("Hello world, it's a song that we're singing");