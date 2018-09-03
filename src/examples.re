open Common;

let component = ReasonReact.statelessComponent("Examples");

let example1 = {
  words: [{
    x: 300.0,
    y: 150.0,
    text: "Ursa",
    velocity: 0.0
  }],
  ticks: 0,
  base: (0.0, 600.0),
  gameOver: false,
  crashCollector: Crash.crashSite(),
  bonus: None
};

let make = _ => {
  ...component,
  render: _ => <Example exampleState={example1} input="Ur" />
};