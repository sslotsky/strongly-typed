open Common;

let component = ReasonReact.statelessComponent("Examples");

let static = words => {
  words,
  captured: [],
  crashed: [],
  ticks: 0,
  base: (0.0, 600.0),
  gameOver: false,
  clear: false,
  crashCollector: Crash.crashSite(0.0, 600.0),
  bonus: None,
};

let example0 =
  static([
    {
      x: 320.0,
      y: 200.0,
      text: "A super duper long phrase that doesn't fit",
      velocity: 0.0,
    },
  ]);

let example1 =
  static([
    {x: 120.0, y: 265.0, text: "Bungalo Bill", velocity: 0.0},
    {x: 20.0, y: 45.0, text: "Barnacles", velocity: 0.0},
    {x: 290.0, y: 120.0, text: "Snuffleupagus", velocity: 0.0},
  ]);

let example2 =
  static([
    {x: 300.0, y: 150.0, text: "Scalawags", velocity: 0.0},
    {x: 80.0, y: 70.0, text: "Marsupial Madness", velocity: 0.0},
  ]);

example2.crashCollector.crash({left: 260.0, right: 315.0});

let example3 =
  static([
    {x: 120.0, y: 265.0, text: "Rocking the Casbah", velocity: 0.0},
    {x: 160.0, y: 200.0, text: "Shindig", velocity: 0.0},
  ]);

example3.crashCollector.crash({left: 260.0, right: 315.0});
example3.crashCollector.crash({left: 520.0, right: 550.0});
example3.crashCollector.crash({left: 20.0, right: 80.0});

let example4 =
  static([{x: 110.0, y: 285.0, text: "Neologisms", velocity: 0.0}]);

example4.crashCollector.crash({left: 10.0, right: 70.0});
example4.crashCollector.crash({left: 80.0, right: 130.0});
example4.crashCollector.crash({left: 200.0, right: 240.0});
example4.crashCollector.crash({left: 260.0, right: 300.0});
example4.crashCollector.crash({left: 470.0, right: 550.0});

let noRightOverlap =
  static([{x: 37.0, y: 250.0, text: "narcolepsy", velocity: 0.0}]);

noRightOverlap.crashCollector.crash({left: 260.0, right: 320.0});
noRightOverlap.crashCollector.crash({left: 350.0, right: 420.0});

let examples = [|
  (example0, "A sup"),
  (example1, "Bungalo B"),
  (noRightOverlap, "narco"),
  (example2, "Scala"),
  (example3, "Roc"),
  (example4, "Neo"),
|];

let style =
  ReactDOMRe.Style.make(~display="flex", ~flexDirection="column", ());

let make = _ => {
  ...component,
  render: _ =>
    <>
      <h1> {ReasonReact.string("Examples")} </h1>
      <div style>
        {
          examples
          |> Array.mapi((i, (state, input)) => {
               let anchor = "example-" ++ i->string_of_int;
               <a key=i->string_of_int href={"#" ++ anchor} id=anchor>
                 <Example exampleState=state input />
               </a>;
             })
          |> ReasonReact.array
        }
      </div>
    </>,
};