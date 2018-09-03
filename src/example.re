open Canvas;

type state = {
  initialized: bool,
};

type action =
  | Ready(option(Dom.element));

let component = ReasonReact.reducerComponent("Example");

let (height, width) = (300.0, 600.0);

let make = (~exampleState: Common.state, ~input, _children) => {
  ...component,
  initialState: () => { initialized: false },
  reducer: (action, state) => switch(action) {
  | Ready(canvas) => switch(canvas, state.initialized) {
    | (Some(node), false) => ReasonReact.UpdateWithSideEffects({ initialized: true }, _ => {
      let context = node->getContext("2d");
      Canvas.renderWords(context, exampleState, width, height, input);
    }) 
    | _ => ReasonReact.NoUpdate
  }},
  render: self => <canvas height={height->string_of_float} width={width->string_of_float} ref={node => self.send(Ready(Js.Nullable.toOption(node)))} />
};