open Common;

type state = {
  initialized: bool,
};

type action =
  | Ready(option(Dom.element));

let component = ReasonReact.reducerComponent("Play");

let (height, width, baseMargin, statusBarHeight) = (600.0, 1200.0, 30.0, 40.0);
let (baseLeft, baseRight) = (baseMargin, width -. baseMargin);
let canvasHeight = height +. statusBarHeight;

let make = (_children) => {
  ...component,
  initialState: () => { initialized: false },
  reducer: (action, state) => switch(action) {
  | Ready(canvas) => switch(canvas, state.initialized) {
    | (Some(node), false) => ReasonReact.UpdateWithSideEffects({ initialized: true }, _ => {
      let initialState = {
        words: [],
        captured: [],
        crashed: [],
        ticks: 0,
        base: (baseLeft, baseRight),
        gameOver: false,
        clear: false,
        crashCollector: Crash.crashSite(baseLeft, baseRight),
        bonus: None
      };

      Canvas.boot(node, height, width, initialState, Game.nextState);
    }) 
    | _ => ReasonReact.NoUpdate
  }},
  render: self => (
    <canvas
      height={canvasHeight->string_of_float}
      width={width->string_of_float}
      ref={node => self.send(Ready(node->Js.Nullable.toOption))}
    />
  )
};