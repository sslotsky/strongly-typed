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
  /* Represent what isn't there. "We don't have any no-cream." */
  crashCollector: crashCollector
};

type ui = {
  height: float,
  width: float,
  fontSize: int,
  input: unit => string,
  clearInput: unit => unit,
  calculateWidth: string => float,
  onCrash: word => unit,
  onCollect: word => unit
};

let startsWith = (input, word) => word.text->Js.Re.test(("^" ++ input)->Js.Re.fromString);
