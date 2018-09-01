type bonus = {
  x: float,
  startY: float,
  offsetY: float,
  amplitude: int,
};

type word = {
  text: string,
  velocity: float,
  x: float,
  y: float
};

type crashSite = {
  left: float,
  right: float
};

type crashCollector = {
  crash: crashSite => unit,
  covers: (float, float) => bool,
  percentCovered: (float, float) => float,
  sites: unit => list(crashSite)
};

type state = {
  gameOver: bool,
  words: list(word),
  ticks: int,
  base: (float, float),
  crashCollector: crashCollector,
  bonus: option(bonus)
};

type ui = {
  paused: unit => bool,
  playPause: unit => unit,
  reset: unit => unit,
  score: unit => int,
  height: float,
  width: float,
  fontSize: int,
  input: unit => string,
  clearInput: unit => unit,
  calculateWidth: string => float,
  onCrash: word => unit,
  onCollect: word => unit
};

let startsWith = (str, input) => str->Js.Re.test(("^" ++ input)->Js.Re.fromString);
let isPrefixOf = (input, word) => word.text->startsWith(input);
