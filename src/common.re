type word = {
  text: string,
  mutable x: float,
  mutable y: float
};

type crashSite = {
  left: float,
  right: float
};

type crashCollector = {
  crash: crashSite => unit,
  covers: (float, float) => bool,
  sites: unit => list(crashSite)
};

type state = {
  mutable gameOver: bool,
  mutable words: list(word),
  mutable ticks: int,
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
  calculateWidth: string => float
};

let startsWith = (input, word) => word.text->Js.Re.test(("^" ++ input)->Js.Re.fromString);
