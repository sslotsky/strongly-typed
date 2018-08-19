type word = {
  text: string,
  mutable x: float,
  mutable y: float
};

type crashSite = {
    left: float,
    right: float
};

type state = {
  mutable words: list(word),
  mutable ticks: int,
  mutable crashSites: list(crashSite)
};

let startsWith = (input, word) => word.text->Js.Re.test(("^" ++ input)->Js.Re.fromString);