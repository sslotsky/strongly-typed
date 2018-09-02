open Common;

type state = {
  initialized: bool,
};

type action =
  | Ready(option(Dom.element));

let component = ReasonReact.reducerComponent("Play");

let (height, width, baseMargin) = (600.0, 1200.0, 30.0);
let canvasHeight = height +. baseMargin +. 10.0;

let make = (_children) => {
  ...component,
  initialState: () => { initialized: false },
  reducer: (action, state) => switch(action) {
  | Ready(canvas) => switch(canvas, state.initialized) {
    | (Some(node), false) => ReasonReact.UpdateWithSideEffects({ initialized: true }, _ => {
      let initialState = {
        words: [],
        ticks: 0,
        base: (baseMargin, width -. baseMargin),
        gameOver: false,
        crashCollector: Crash.crashSite(),
        bonus: None
      };

      Canvas.boot(node, height, width, initialState, Game.nextState);
    }) 
    | _ => ReasonReact.NoUpdate
  }},
  render: self => <canvas height={canvasHeight->string_of_float} width={width->string_of_float} ref={node => self.send(Ready(Js.Nullable.toOption(node)))} />
};