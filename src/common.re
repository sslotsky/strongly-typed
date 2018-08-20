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
  sites: unit => list(crashSite)
};

type state = {
  mutable words: list(word),
  mutable ticks: int,
  /* Represent what isn't there. "We don't have any no-cream." */
  crashCollector: crashCollector
};

let startsWith = (input, word) => word.text->Js.Re.test(("^" ++ input)->Js.Re.fromString);
