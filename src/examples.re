open Common;

let component = ReasonReact.statelessComponent("Examples");

let example1 = {
  words: [{
    x: 300.0,
    y: 150.0,
    text: "Scalawags",
    velocity: 0.0
  }, {
    x: 80.0,
    y: 70.0,
    text: "Marsupial Madness",
    velocity: 0.0
  }],
  ticks: 0,
  base: (0.0, 600.0),
  gameOver: false,
  crashCollector: Crash.crashSite(),
  bonus: None
};

example1.crashCollector.crash({ left: 260.0, right: 315.0});
let examples = [|(example1, "Scal")|];

let make = _ => {
  ...component,
  render: _ =>
    <div>
      <h1> (ReasonReact.string("Examples")) </h1>
      (
        examples
          |> Array.mapi((i, (state, input)) => <Example key={i->string_of_int} exampleState={state} input={input} />)
          |> ReasonReact.array
      )
    </div>
};