open Common;

let component = ReasonReact.statelessComponent("Examples");

let static = words => {
  words,
  ticks: 0,
  base: (0.0, 600.0),
  gameOver: false,
  crashCollector: Crash.crashSite(),
  bonus: None
};

let example1 = static([
  {
    x: 120.0,
    y: 265.0,
    text: "Bungalo Bill",
    velocity: 0.0
  }, {
    x: 20.0,
    y: 45.0,
    text: "Barnacles",
    velocity: 0.0
  }, {
    x: 290.0,
    y: 120.0,
    text: "Snuffleupagus",
    velocity: 0.0
  }
]);

let example2 = static([
  {
    x: 300.0,
    y: 150.0,
    text: "Scalawags",
    velocity: 0.0
  }, {
    x: 80.0,
    y: 70.0,
    text: "Marsupial Madness",
    velocity: 0.0
  }
]);

example2.crashCollector.crash({ left: 260.0, right: 315.0});

let example3 = static([
  {
    x: 120.0,
    y: 265.0,
    text: "Rocking the Casbah",
    velocity: 0.0
  }, {
    x: 160.0,
    y: 200.0,
    text: "Shindig",
    velocity: 0.0

  }
]);

example3.crashCollector.crash({ left: 260.0, right: 315.0});
example3.crashCollector.crash({ left: 520.0, right: 550.0});

let example4 = static([
  {
    x: 110.0,
    y: 285.0,
    text: "Neologisms",
    velocity: 0.0
  }
]);

example4.crashCollector.crash({ left: 100.0, right: 130.0});
example4.crashCollector.crash({ left: 260.0, right: 315.0});
example4.crashCollector.crash({ left: 325.0, right: 400.0});
example4.crashCollector.crash({ left: 500.0, right: 550.0});

let examples = [|(example1, "Bungalo B"), (example2, "Scala"), (example3, "Roc"), (example4, "Neo")|];

let style = ReactDOMRe.Style.make(~display="flex", ~flexDirection="column", ());

let make = _ => {
  ...component,
  render: _ =>
    <>
      <h1> (ReasonReact.string("Examples")) </h1>
      <div style={style}>
        (
          examples
          |>  Array.mapi((i, (state, input)) => {
                let anchor = "example-" ++ i->string_of_int;
                <a key={i->string_of_int} href={"#" ++ anchor} id={anchor}>
                  <Example exampleState={state} input={input} />
                </a>
              })
          |>  ReasonReact.array
        )
      </div>
    </>
};