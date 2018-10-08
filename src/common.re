type bonus = {
  x: float,
  startY: float,
  offsetY: float,
  amplitude: int
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
  crash: crashSite => bool,
  covers: (float, float) => bool,
  percentCovered: (float, float) => float,
  sites: unit => list(crashSite)
};

type state = {
  gameOver: bool,
  words: list(word),
  captured: list(word),
  crashed: list(word),
  ticks: int,
  base: (float, float),
  crashCollector: crashCollector,
  bonus: option(bonus),
  clear: bool
};

type ui = {
  height: float,
  width: float,
  input: unit => string,
  calculateWidth: string => float
};

let startsWith = (str, input) => str->Js.Re.test(("^" ++ input)->Js.Re.fromString);
let isPrefixOf = (input, word) => word.text->startsWith(input);
let bonusWord = "manifold";
